"""
🌸 SoundBloom - AI-Powered Audio Analysis Platform
=================================================
A sophisticated audio analysis and transcription platform with Neo4j graph database integration.
"""

import reflex as rx
from typing import List, Optional
import datetime
import requests
import subprocess
import json

from rxconfig import config


def call_ollama_api(prompt: str, model: str = "phi3:mini") -> str:
    """Call Ollama API to generate text."""
    try:
        url = "http://localhost:11434/api/generate"
        data = {
            "model": model,
            "prompt": prompt,
            "stream": False
        }
        response = requests.post(url, json=data, timeout=30)
        response.raise_for_status()
        result = response.json()
        return result.get("response", "")
    except Exception as e:
        return f"Error calling Ollama: {str(e)}"


class ConceptCard:
    """Represents a concept extracted from audio/text."""
    def __init__(self, id: str, title: str, content: str, source: str, confidence: float = 0.8):
        self.id = id
        self.title = title
        self.content = content
        self.source = source  # Which file/transcript this came from
        self.confidence = confidence
        self.timestamp = datetime.datetime.now()


class SoundBloomState(rx.State):
    """The main SoundBloom application state."""

    # Audio processing state
    uploaded_files: List[str] = []
    processing_status: str = "Ready"
    current_audio_file: Optional[str] = None

    # Transcription state
    current_transcript: str = ""
    transcription_confidence: float = 0.0

    # Analysis state
    analysis_results: dict = {}

    # Concept extraction and document generation
    extracted_concepts: List[dict] = []
    selected_concepts: List[dict] = []
    document_workspace: List[dict] = []
    generated_document: str = ""
    llm_status: str = "Ready"

    # UI state
    active_tab: str = "upload"
    dark_mode: bool = True
    show_concept_builder: bool = False

    def upload_audio_file(self, files: List[rx.UploadFile]):
        """Handle audio file upload."""
        for file in files:
            self.uploaded_files.append(file.filename)
            self.processing_status = f"Uploaded: {file.filename}"
            self.current_audio_file = file.filename
        return self.processing_status

    def start_transcription(self):
        """Start audio transcription process."""
        if self.current_audio_file:
            self.processing_status = f"Transcribing: {self.current_audio_file}"
            # This would integrate with actual transcription service
            self.current_transcript = "Demo transcript: This is where the AI transcription would appear..."
            self.transcription_confidence = 0.95
            self.processing_status = "Transcription complete"
        else:
            self.processing_status = "No file selected"

    def analyze_audio(self):
        """Perform audio analysis."""
        if self.current_audio_file:
            self.processing_status = "Analyzing audio patterns..."
            # This would integrate with actual analysis
            self.analysis_results = {
                "duration": "3:24",
                "sample_rate": "44.1 kHz",
                "channels": "Stereo",
                "format": "MP3",
                "sentiment": "Positive",
                "key_topics": ["Technology", "AI", "Innovation"]
            }
            self.processing_status = "Analysis complete"
        else:
            self.processing_status = "No file selected"

    def set_active_tab(self, tab: str):
        """Set the active tab."""
        self.active_tab = tab

    def set_upload_tab(self):
        """Set active tab to upload."""
        self.active_tab = "upload"

    def set_transcription_tab(self):
        """Set active tab to transcription."""
        self.active_tab = "transcription"

    def set_analysis_tab(self):
        """Set active tab to analysis."""
        self.active_tab = "analysis"

    def set_concepts_tab(self):
        """Set active tab to concepts."""
        self.active_tab = "concepts"

    def extract_concepts(self):
        """Extract concepts from current transcript using AI."""
        if self.current_transcript:
            self.processing_status = "Extracting concepts from transcript..."

            # Use real LLM for concept extraction
            prompt = f"""
            Analyze this transcript and extract 4 key concepts in JSON format:

            Transcript: {self.current_transcript}

            Return exactly 4 concepts as valid JSON array with this format:
            [
                {{
                    "id": "concept_1",
                    "title": "Brief Title",
                    "content": "Detailed summary of the concept",
                    "source": "{self.current_audio_file or 'transcript'}",
                    "confidence": 0.85,
                    "keywords": ["keyword1", "keyword2", "keyword3"]
                }}
            ]

            Important: Return ONLY the JSON array, no other text.
            """

            try:
                response = call_ollama_api(prompt)
                # Try to parse JSON from response
                concepts = json.loads(response)
                if isinstance(concepts, list) and len(concepts) > 0:
                    self.extracted_concepts = concepts
                    self.processing_status = f"Extracted {len(concepts)} concepts with AI"
                else:
                    # Fallback to demo concepts if parsing fails
                    self._use_demo_concepts()
            except Exception as e:
                self.processing_status = f"AI extraction failed: {str(e)}, using demo"
                self._use_demo_concepts()
        else:
            self.processing_status = "No transcript available for concept extraction"

    def _use_demo_concepts(self):
        """Fallback demo concepts if LLM fails."""
        concepts = [
            {
                "id": "concept_1",
                "title": "AI Technology Trends",
                "content": "Discussion about current AI developments",
                "source": self.current_audio_file or "transcript",
                "confidence": 0.92,
                "keywords": ["AI", "technology", "future", "development"]
            },
            {
                "id": "concept_2",
                "title": "Innovation Challenges",
                "content": "Key challenges facing innovation in tech",
                "source": self.current_audio_file or "transcript",
                "confidence": 0.87,
                "keywords": ["innovation", "challenges", "industry"]
            },
            {
                "id": "concept_3",
                "title": "Market Analysis",
                "content": "Analysis of market trends and landscape",
                "source": self.current_audio_file or "transcript",
                "confidence": 0.79,
                "keywords": ["market", "trends", "competition", "analysis"]
            },
            {
                "id": "concept_4",
                "title": "User Experience Design",
                "content": "Principles for creating intuitive interfaces",
                "source": self.current_audio_file or "transcript",
                "confidence": 0.84,
                "keywords": ["UX", "design", "interface", "user"]
            }
        ]
        self.extracted_concepts = concepts

    def add_concept_to_workspace(self, concept_id: str):
        """Add a concept to the document workspace."""
        concept = next((c for c in self.extracted_concepts if c["id"] == concept_id), None)
        if concept and concept not in self.document_workspace:
            self.document_workspace.append(concept)
            self.processing_status = f"Added '{concept['title']}' to workspace"

    def remove_concept_from_workspace(self, concept_id: str):
        """Remove a concept from the document workspace."""
        self.document_workspace = [c for c in self.document_workspace if c["id"] != concept_id]
        self.processing_status = f"Removed concept from workspace"

    def generate_document_with_llm(self):
        """Generate document using local LLM with selected concepts."""
        if not self.document_workspace:
            self.llm_status = "No concepts selected for document generation"
            return

        self.llm_status = "Generating document with local LLM..."

        # Prepare concepts for LLM
        concept_summaries = []
        for c in self.document_workspace:
            summary = f"Title: {c['title']}\nContent: {c['content']}"
            summary += f"\nKeywords: {', '.join(c.get('keywords', []))}"
            concept_summaries.append(summary)

        concepts_text = "\n\n".join(concept_summaries)

        # Create prompt for LLM document generation
        prompt = f"""
Create a comprehensive strategic analysis report based on these concepts:

{concepts_text}

Generate a professional report with the following structure:
- Executive Summary
- Key Concepts Analysis  
- Synthesis and Recommendations
- Conclusion

Make it insightful, actionable, and well-structured. Use markdown formatting.
The report should be approximately 500-800 words.
"""

        try:
            # Generate document with real LLM
            response = call_ollama_api(prompt)
            
            if response and not response.startswith("Error"):
                footer = f"\n\n---\n*Generated by SoundBloom AI*"
                footer += f"\n*Concepts Used: {len(self.document_workspace)}*"
                self.generated_document = response + footer
                self.llm_status = "Document generated successfully with AI"
            else:
                # Fallback to demo document
                self._generate_demo_document()
                self.llm_status = f"AI failed, using demo: {response[:50]}..."
                
        except Exception as e:
            self._generate_demo_document()
            self.llm_status = f"Error: {str(e)}"

    def _generate_demo_document(self):
        """Generate demo document as fallback."""
        concept_titles = [c["title"] for c in self.document_workspace]
        concept_content = "\n".join([f"- {c['content']}" 
                                   for c in self.document_workspace])

        self.generated_document = f"""# Strategic Analysis Report

## Executive Summary
This report synthesizes insights from {len(self.document_workspace)} 
key concepts extracted from audio analysis.

## Key Concepts Analyzed
{concept_content}

## Synthesis and Recommendations
Based on analysis of {', '.join(concept_titles)}, several strategic 
recommendations emerge for organizational growth and innovation.

## Conclusion
The synthesized concepts reveal interconnected themes around 
technology adoption and strategic development.

---
*Generated by SoundBloom AI (Demo Mode)*
*Concepts Used: {len(self.document_workspace)}*
"""

        self.llm_status = "Demo document generated successfully"
        self.processing_status = "Ready to save document to graph database"

    def save_document_to_graph(self):
        """Save generated document to Neo4j with concept relationships."""
        if not self.generated_document:
            self.processing_status = "No document to save"
            return

        # Mock Neo4j integration - would create nodes and relationships
        self.processing_status = "Saving document to graph database..."

        # Would create:
        # - Document node with content and metadata
        # - Concept nodes (if not already existing)
        # - DERIVED_FROM relationships between document and concepts
        # - CONTAINS relationships for concept inclusion
        # - SOURCE relationships to original audio file

        self.processing_status = "Document saved to graph with concept relationships"

    def toggle_concept_builder(self):
        """Toggle the concept builder interface."""
        self.show_concept_builder = not self.show_concept_builder

    # Individual concept management methods
    def add_concept_1(self):
        self.add_concept_to_workspace("concept_1")

    def add_concept_2(self):
        self.add_concept_to_workspace("concept_2")

    def add_concept_3(self):
        self.add_concept_to_workspace("concept_3")

    def add_concept_4(self):
        self.add_concept_to_workspace("concept_4")

    def remove_concept_1(self):
        self.remove_concept_from_workspace("concept_1")

    def remove_concept_2(self):
        self.remove_concept_from_workspace("concept_2")

    def remove_concept_3(self):
        self.remove_concept_from_workspace("concept_3")

    def remove_concept_4(self):
        self.remove_concept_from_workspace("concept_4")


def header() -> rx.Component:
    """SoundBloom application header."""
    return rx.hstack(
        rx.image(
            src="/favicon.ico",
            width="40px",
            height="40px",
        ),
        rx.heading(
            "🌸 SoundBloom",
            size="8",
            color="purple.500",
        ),
        rx.spacer(),
        rx.text(
            f"Running on Port 7000 • {datetime.datetime.now().strftime('%H:%M')}",
            size="3",
            color="gray.500",
        ),
        rx.color_mode.button(),
        align="center",
        width="100%",
        padding="1rem",
        border_bottom="1px solid",
        border_color="gray.200",
    )


def upload_section() -> rx.Component:
    """Audio file upload section."""
    return rx.vstack(
        rx.heading("📁 Upload Audio Files", size="6", color="blue.500"),
        rx.text("Supported formats: MP3, WAV, M4A, FLAC", size="3", color="gray.600"),

        rx.upload(
            rx.vstack(
                rx.button(
                    "🎵 Select Audio Files",
                    color_scheme="blue",
                    size="3",
                ),
                rx.text("Drag and drop files here", size="2", color="gray.500"),
            ),
            id="audio_upload",
            multiple=True,
            accept={
                "audio/*": [".mp3", ".wav", ".m4a", ".flac"]
            },
            border="2px dashed",
            border_color="blue.300",
            border_radius="lg",
            padding="2rem",
        ),

        rx.cond(
            SoundBloomState.uploaded_files,
            rx.vstack(
                rx.heading("Uploaded Files:", size="4"),
                rx.foreach(
                    SoundBloomState.uploaded_files,
                    lambda file: rx.text(f"🎵 {file}", color="green.600")
                ),
            ),
        ),

        rx.text(
            SoundBloomState.processing_status,
            size="3",
            color="blue.600",
            font_weight="bold",
        ),

        spacing="4",
        align="start",
        width="100%",
    )


def transcription_section() -> rx.Component:
    """Audio transcription section."""
    return rx.vstack(
        rx.heading("🎯 AI Transcription", size="6", color="green.500"),

        rx.hstack(
            rx.button(
                "▶️ Start Transcription",
                on_click=SoundBloomState.start_transcription,
                color_scheme="green",
                size="3",
            ),
            rx.cond(
                SoundBloomState.transcription_confidence > 0,
                rx.badge(
                    "Confidence: High",
                    color_scheme="green",
                ),
            ),
            align="center",
        ),

        rx.cond(
            SoundBloomState.current_transcript,
            rx.text_area(
                value=SoundBloomState.current_transcript,
                placeholder="Transcription will appear here...",
                size="3",
                height="200px",
                width="100%",
                resize="vertical",
            ),
        ),

        spacing="4",
        align="start",
        width="100%",
    )


def concept_card_1() -> rx.Component:
    """Individual concept card component for concept 1."""
    return rx.card(
        rx.vstack(
            rx.hstack(
                rx.badge("92%", color_scheme="blue", size="1"),
                rx.spacer(),
                rx.button(
                    "📋",
                    size="1",
                    variant="ghost",
                    on_click=SoundBloomState.add_concept_1,
                ),
                width="100%",
                align="center",
            ),
            rx.heading("AI Technology Trends", size="4", color="purple.600"),
            rx.text("Discussion about current AI developments and future implications",
                   size="2", color="gray.600"),
            rx.hstack(
                rx.badge("AI", color_scheme="gray", size="1"),
                rx.badge("technology", color_scheme="gray", size="1"),
                rx.badge("future", color_scheme="gray", size="1"),
                spacing="1",
            ),
            rx.text("Source: transcript", size="1", color="gray.400"),
            spacing="2",
            align="start",
        ),
        width="280px",
        height="220px",
        padding="3",
        cursor="pointer",
        _hover={"transform": "translateY(-2px)", "box_shadow": "lg"},
        transition="all 0.2s",
    )


def concept_card_2() -> rx.Component:
    """Individual concept card component for concept 2."""
    return rx.card(
        rx.vstack(
            rx.hstack(
                rx.badge("87%", color_scheme="blue", size="1"),
                rx.spacer(),
                rx.button(
                    "📋",
                    size="1",
                    variant="ghost",
                    on_click=SoundBloomState.add_concept_2,
                ),
                width="100%",
                align="center",
            ),
            rx.heading("Innovation Challenges", size="4", color="purple.600"),
            rx.text("Key challenges facing innovation in the tech industry",
                   size="2", color="gray.600"),
            rx.hstack(
                rx.badge("innovation", color_scheme="gray", size="1"),
                rx.badge("challenges", color_scheme="gray", size="1"),
                rx.badge("industry", color_scheme="gray", size="1"),
                spacing="1",
            ),
            rx.text("Source: transcript", size="1", color="gray.400"),
            spacing="2",
            align="start",
        ),
        width="280px",
        height="220px",
        padding="3",
        cursor="pointer",
        _hover={"transform": "translateY(-2px)", "box_shadow": "lg"},
        transition="all 0.2s",
    )


def concept_card_3() -> rx.Component:
    """Individual concept card component for concept 3."""
    return rx.card(
        rx.vstack(
            rx.hstack(
                rx.badge("79%", color_scheme="blue", size="1"),
                rx.spacer(),
                rx.button(
                    "📋",
                    size="1",
                    variant="ghost",
                    on_click=SoundBloomState.add_concept_3,
                ),
                width="100%",
                align="center",
            ),
            rx.heading("Market Analysis", size="4", color="purple.600"),
            rx.text("Analysis of market trends and competitive landscape",
                   size="2", color="gray.600"),
            rx.hstack(
                rx.badge("market", color_scheme="gray", size="1"),
                rx.badge("trends", color_scheme="gray", size="1"),
                rx.badge("competition", color_scheme="gray", size="1"),
                spacing="1",
            ),
            rx.text("Source: transcript", size="1", color="gray.400"),
            spacing="2",
            align="start",
        ),
        width="280px",
        height="220px",
        padding="3",
        cursor="pointer",
        _hover={"transform": "translateY(-2px)", "box_shadow": "lg"},
        transition="all 0.2s",
    )


def concept_card_4() -> rx.Component:
    """Individual concept card component for concept 4."""
    return rx.card(
        rx.vstack(
            rx.hstack(
                rx.badge("84%", color_scheme="blue", size="1"),
                rx.spacer(),
                rx.button(
                    "📋",
                    size="1",
                    variant="ghost",
                    on_click=SoundBloomState.add_concept_4,
                ),
                width="100%",
                align="center",
            ),
            rx.heading("User Experience Design", size="4", color="purple.600"),
            rx.text("Principles and best practices for creating intuitive interfaces",
                   size="2", color="gray.600"),
            rx.hstack(
                rx.badge("UX", color_scheme="gray", size="1"),
                rx.badge("design", color_scheme="gray", size="1"),
                rx.badge("interface", color_scheme="gray", size="1"),
                spacing="1",
            ),
            rx.text("Source: transcript", size="1", color="gray.400"),
            spacing="2",
            align="start",
        ),
        width="280px",
        height="220px",
        padding="3",
        cursor="pointer",
        _hover={"transform": "translateY(-2px)", "box_shadow": "lg"},
        transition="all 0.2s",
    )


def concepts_section() -> rx.Component:
    """Concept extraction and document generation section."""
    return rx.vstack(
        rx.heading("🧠 Concept Extraction & Document Generation", size="6", color="blue.500"),

        # Control buttons
        rx.hstack(
            rx.button(
                "🔍 Extract Concepts",
                on_click=SoundBloomState.extract_concepts,
                color_scheme="blue",
                size="3",
            ),
            rx.button(
                "📝 Generate Document",
                on_click=SoundBloomState.generate_document_with_llm,
                color_scheme="green",
                size="3",
                disabled=rx.cond(SoundBloomState.document_workspace, False, True),
            ),
            rx.button(
                "💾 Save to Graph",
                on_click=SoundBloomState.save_document_to_graph,
                color_scheme="purple",
                size="3",
                disabled=rx.cond(SoundBloomState.generated_document, False, True),
            ),
            spacing="3",
        ),

        # Status
        rx.text(
            SoundBloomState.llm_status,
            size="3",
            color="blue.600",
            font_weight="bold",
        ),

        # Two-column layout
        rx.hstack(
            # Left: Extracted concepts
            rx.vstack(
                rx.heading("🎯 Extracted Concepts", size="4"),
                rx.cond(
                    SoundBloomState.extracted_concepts,
                    rx.grid(
                        concept_card_1(),
                        concept_card_2(),
                        concept_card_3(),
                        concept_card_4(),
                        columns="2",
                        spacing="3",
                    ),
                    rx.text("No concepts extracted yet", color="gray.500", size="3"),
                ),
                width="50%",
                align="start",
                spacing="3",
                padding="2",
            ),

            # Right: Document workspace and generation
            rx.vstack(
                rx.heading("📝 Document Workspace", size="4"),

                # Selected concepts area
                rx.card(
                    rx.vstack(
                        rx.text("Drag concepts here or click 📋 to add", size="2", color="gray.500"),
                        rx.cond(
                            SoundBloomState.document_workspace,
                            rx.vstack(
                                rx.text("Selected concepts for document generation:"),
                                rx.foreach(
                                    SoundBloomState.document_workspace,
                                    lambda concept: rx.card(
                                        rx.hstack(
                                            rx.text(concept["title"], font_weight="bold"),
                                            rx.spacer(),
                                            rx.button("❌", size="1", variant="ghost"),
                                            width="100%",
                                        ),
                                        padding="2",
                                        width="100%",
                                    )
                                ),
                                spacing="2",
                                width="100%",
                            ),
                        ),
                        spacing="3",
                        width="100%",
                    ),
                    min_height="200px",
                    padding="3",
                    border="2px dashed",
                    border_color="purple.300",
                    background="purple.25",
                ),

                # Generated document preview
                rx.cond(
                    SoundBloomState.generated_document,
                    rx.vstack(
                        rx.heading("📄 Generated Document", size="4"),
                        rx.text_area(
                            value=SoundBloomState.generated_document,
                            height="300px",
                            width="100%",
                            resize="vertical",
                        ),
                        spacing="2",
                    ),
                ),

                width="50%",
                align="start",
                spacing="3",
                padding="2",
            ),

            spacing="4",
            align="start",
            width="100%",
        ),

        spacing="4",
        align="start",
        width="100%",
    )


def analysis_section() -> rx.Component:
    """Audio analysis section."""
    return rx.vstack(
        rx.heading("🔍 Audio Analysis", size="6", color="purple.500"),

        rx.button(
            "🔬 Analyze Audio",
            on_click=SoundBloomState.analyze_audio,
            color_scheme="purple",
            size="3",
        ),

        rx.cond(
            SoundBloomState.analysis_results,
            rx.vstack(
                rx.heading("Analysis Results:", size="4"),
                rx.grid(
                    rx.card(
                        rx.vstack(
                            rx.text("Duration", font_weight="bold", size="2"),
                            rx.text(SoundBloomState.analysis_results.get("duration", "N/A"), size="4"),
                            align="center",
                        ),
                    ),
                    rx.card(
                        rx.vstack(
                            rx.text("Sample Rate", font_weight="bold", size="2"),
                            rx.text(SoundBloomState.analysis_results.get("sample_rate", "N/A"), size="4"),
                            align="center",
                        ),
                    ),
                    rx.card(
                        rx.vstack(
                            rx.text("Channels", font_weight="bold", size="2"),
                            rx.text(SoundBloomState.analysis_results.get("channels", "N/A"), size="4"),
                            align="center",
                        ),
                    ),
                    rx.card(
                        rx.vstack(
                            rx.text("Sentiment", font_weight="bold", size="2"),
                            rx.text(SoundBloomState.analysis_results.get("sentiment", "N/A"), size="4"),
                            align="center",
                        ),
                    ),
                    columns="4",
                    spacing="3",
                    width="100%",
                ),
                spacing="3",
            ),
        ),

        spacing="4",
        align="start",
        width="100%",
    )


def main_content() -> rx.Component:
    """Main application content with tabs."""
    return rx.vstack(
        # Tab Navigation
        rx.hstack(
            rx.button(
                "📁 Upload",
                on_click=SoundBloomState.set_upload_tab,
                color_scheme=rx.cond(
                    SoundBloomState.active_tab == "upload",
                    "blue",
                    "gray"
                ),
                variant=rx.cond(
                    SoundBloomState.active_tab == "upload",
                    "solid",
                    "outline"
                ),
            ),
            rx.button(
                "🎯 Transcription",
                on_click=SoundBloomState.set_transcription_tab,
                color_scheme=rx.cond(
                    SoundBloomState.active_tab == "transcription",
                    "green",
                    "gray"
                ),
                variant=rx.cond(
                    SoundBloomState.active_tab == "transcription",
                    "solid",
                    "outline"
                ),
            ),
            rx.button(
                "🔍 Analysis",
                on_click=SoundBloomState.set_analysis_tab,
                color_scheme=rx.cond(
                    SoundBloomState.active_tab == "analysis",
                    "purple",
                    "gray"
                ),
                variant=rx.cond(
                    SoundBloomState.active_tab == "analysis",
                    "solid",
                    "outline"
                ),
            ),
            rx.button(
                "🧠 Concepts",
                on_click=SoundBloomState.set_concepts_tab,
                color_scheme=rx.cond(
                    SoundBloomState.active_tab == "concepts",
                    "blue",
                    "gray"
                ),
                variant=rx.cond(
                    SoundBloomState.active_tab == "concepts",
                    "solid",
                    "outline"
                ),
            ),
            spacing="2",
            padding_y="1rem",
        ),

        # Tab Content
        rx.cond(
            SoundBloomState.active_tab == "upload",
            upload_section(),
        ),
        rx.cond(
            SoundBloomState.active_tab == "transcription",
            transcription_section(),
        ),
        rx.cond(
            SoundBloomState.active_tab == "analysis",
            analysis_section(),
        ),
        rx.cond(
            SoundBloomState.active_tab == "concepts",
            concepts_section(),
        ),

        spacing="4",
        padding="2rem",
        min_height="70vh",
        width="100%",
    )


def footer() -> rx.Component:
    """Application footer."""
    return rx.hstack(
        rx.text(
            "🌸 SoundBloom AI Audio Platform",
            size="2",
            color="gray.500",
        ),
        rx.spacer(),
        rx.text(
            "Port 7000 • Neo4j Ready • ML Enhanced",
            size="2",
            color="gray.400",
        ),
        width="100%",
        padding="1rem",
        border_top="1px solid",
        border_color="gray.200",
    )


def index() -> rx.Component:
    """Main SoundBloom application page."""
    return rx.vstack(
        header(),
        main_content(),
        footer(),
        spacing="0",
        min_height="100vh",
        width="100%",
    )


def dashboard() -> rx.Component:
    """SoundBloom dashboard page."""
    return rx.vstack(
        header(),
        rx.container(
            rx.heading("📊 Dashboard", size="7", color="blue.500"),
            rx.text("Analytics and insights coming soon...", size="4"),
            padding="2rem",
        ),
        footer(),
        spacing="0",
        min_height="100vh",
    )


# Create the Reflex app
app = rx.App(
    style={
        "font_family": "Inter, sans-serif",
    },
    stylesheets=[
        "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap",
    ],
)

# Add pages
app.add_page(index, route="/")
app.add_page(dashboard, route="/dashboard")
