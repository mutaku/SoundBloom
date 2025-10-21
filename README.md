# 🌸 SoundBloom

**AI-Powered Concept Analysis & Document Generation**

SoundBloom is a sophisticated platform that uses local AI to extract concepts from your content and synthesize them into professional documents. All processing happens locally for complete privacy and security.

## ✨ Features

- 🧠 **AI Concept Extraction**: Automatically extract key concepts from transcripts
- 📄 **Document Generation**: Transform concepts into professional strategic reports  
- 🎯 **Interactive Workflow**: Concept cards → workspace → document synthesis
- 🔒 **100% Local Processing**: Complete privacy with offline AI (Ollama)
- 🎨 **Modern Web Interface**: Clean, intuitive user experience
- 📊 **Graph Integration**: Neo4j support for concept relationships (planned)

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- [Poetry](https://python-poetry.org/docs/#installation) 
- [Ollama](https://ollama.com/) (for local AI)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mutaku/SoundBloom.git
   cd SoundBloom
   ```

2. **Install dependencies**
   ```bash
   poetry install
   ```

3. **Install and start Ollama**
   ```bash
   # Install Ollama (Windows)
   winget install Ollama.Ollama
   
   # Pull the AI model
   ollama pull phi3:mini
   ```

4. **Start SoundBloom**
   ```bash
   python start.py
   ```
   
   Or use Poetry directly:
   ```bash
   poetry run python start.py
   ```

5. **Open in browser**: http://localhost:3000

## 📁 Project Structure

```
SoundBloom/
├── SoundBloom/           # Main Reflex application
├── examples/             # Demo applications  
├── tests/               # Test files
├── scripts/             # Utility scripts (PowerShell/batch)
├── docs/                # Documentation
├── assets/              # Static assets
├── data/                # Data storage (gitignored)
├── start.py             # Main startup script
└── README.md            # This file
```

## 🛠️ Development

### Running Tests
```bash
poetry run python -m pytest tests/
```

### Running the Demo
```bash
poetry run python examples/soundbloom_demo.py
```

### Working with the Reflex App
```bash
poetry run reflex run --frontend-port 3000
```

## 📖 Usage Guide

### 1. Concept Extraction
- Input your transcript or content
- AI automatically extracts key concepts
- Each concept includes: title, content, keywords, confidence score

### 2. Document Generation  
- Select concepts for your document workspace
- AI synthesizes concepts into professional reports
- Output includes: executive summary, analysis, recommendations

### 3. Interactive Workflow
- Drag and drop concept cards
- Real-time document generation  
- Professional formatting with markdown support

## 🤖 AI Integration

SoundBloom uses **Ollama** with the **phi3:mini** model for:
- Concept extraction from text
- Document synthesis and generation
- All processing happens locally for privacy

### Supported Models
- `phi3:mini` (recommended, 3.8B parameters)  
- `llama2` (7B+ parameters)
- `codellama` (specialized for technical content)

## 🔧 Configuration

### Environment Variables
Create `.env` file (see `.env.example`):
```env
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=phi3:mini
LOG_LEVEL=INFO
```

### Ollama Configuration
```bash
# Start Ollama service
ollama serve

# List available models  
ollama list

# Pull additional models
ollama pull llama2
```

## 📚 Documentation

- [Setup Guide](docs/SETUP.md) - Detailed installation instructions
- [Concept Workflow](docs/CONCEPT_WORKFLOW.md) - Technical implementation details
- [System Architecture](docs/SYSTEM_READY.md) - Architecture overview
- [Quick Start Guide](docs/QUICK_START.md) - Getting started tutorial

## 🧪 Examples

### Basic Concept Extraction
```python
from SoundBloom.SoundBloom import SoundBloomState

state = SoundBloomState()
state.current_transcript = "Your content here..."
state.extract_concepts()
print(state.extracted_concepts)
```

### Document Generation
```python
# Add concepts to workspace
for concept in state.extracted_concepts:
    state.add_concept_to_workspace(concept["id"])

# Generate document
state.generate_document_with_llm()
print(state.generated_document)
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Add tests if applicable
5. Commit: `git commit -m "Add feature"`
6. Push: `git push origin feature-name` 
7. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Reflex](https://reflex.dev/) - Modern web framework for Python
- [Ollama](https://ollama.com/) - Local AI model management
- [Neo4j](https://neo4j.com/) - Graph database for concept relationships
- Microsoft phi3 - High-quality local AI model

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/mutaku/SoundBloom/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/mutaku/SoundBloom/discussions)  
- 📧 **Email**: Create an issue for support requests

---

**🌸 SoundBloom - Transform your ideas into insights with AI**

**Voice-powered Knowledge Management System**

SoundBloom is an intelligent system that transforms voice recordings into a connected knowledge graph. It imports audio files, transcribes them using local AI models, extracts abstract ideas and concepts, and creates an interconnected web of knowledge that you can explore and build upon.

## ✨ Features

### 🎤 Voice Recording Management
- Import recordings from USB devices
- Organize with metadata, tags, and descriptions
- Support for multiple audio formats (WAV, MP3, FLAC, M4A, OGG)

### 🤖 AI-Powered Processing
- **Local Transcription**: Uses OpenAI Whisper for offline, privacy-focused transcription
- **Concept Extraction**: Identifies abstract ideas and concepts using LLMs
- **Semantic Embeddings**: Creates searchable embeddings for all text content
- **Smart Linking**: Automatically connects related ideas across recordings

### 🕸️ Knowledge Graph
- **Neo4j Database**: Stores recordings, transcripts, and concepts in a graph structure
- **Hierarchical Concepts**: From specific details to abstract principles
- **Relationship Mapping**: Tracks how ideas connect and evolve
- **Semantic Search**: Find related content through embeddings

### 🎯 Intelligent Discovery
- **Concept Cards**: Visual interface for exploring ideas
- **Smart Linking**: Find connections between recordings through shared concepts
- **Document Generation**: Combine multiple concepts to generate new insights
- **Idea Evolution**: Track how concepts develop across recordings

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Reflex Web    │    │   Processing    │    │     Neo4j       │
│   Interface     │◄──►│    Pipeline     │◄──►│   Knowledge     │
│                 │    │                 │    │     Graph       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐             │
         │              │  Local Models   │             │
         └─────────────►│  • Whisper      │◄────────────┘
                        │  • Embeddings   │
                        │  • LLMs         │
                        └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Python 3.10+** (required for modern package versions)
- **Neo4j Database** (local or cloud instance)
- **Git** for version control
- **Poetry** for dependency management

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mutaku/SoundBloom.git
   cd SoundBloom
   ```

2. **Install Python 3.10+ if needed**
   - Windows: Download from [python.org](https://www.python.org/downloads/)
   - macOS: `brew install python@3.10`
   - Linux: `sudo apt install python3.10`

3. **Install Poetry**
   ```bash
   curl -sSL https://install.python-poetry.org | python3 -
   ```

4. **Install dependencies**
   ```bash
   poetry install
   ```

5. **Set up Neo4j**
   - **Option A - Docker**: `docker run -p 7474:7474 -p 7687:7687 neo4j:5.0`
   - **Option B - Neo4j Desktop**: Download from [neo4j.com](https://neo4j.com/download/)
   - **Option C - Cloud**: Use Neo4j AuraDB

6. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

7. **Initialize database**
   ```bash
   poetry run python -m soundbloom.database.init
   ```

8. **Start the application**
   ```bash
   poetry run python soundbloom/app.py
   ```

### Environment Variables

Create a `.env` file:

```bash
# Database
NEO4J_URI=neo4j://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=your_password

# AI Models (optional)
OPENAI_API_KEY=your_openai_key
WHISPER_MODEL=base  # tiny, base, small, medium, large
EMBEDDING_MODEL=all-MiniLM-L6-v2

# Application
DEBUG=true
HOST=localhost
PORT=3000
```

## 📋 Usage Workflow

### 1. Import Recordings
- Connect USB device with audio files
- Use the Import page to scan and select files
- Recordings are copied to local data directory

### 2. Transcription
- Select recordings for transcription
- Whisper processes audio locally (no cloud needed)
- Transcripts are segmented with timestamps

### 3. Concept Extraction
- AI analyzes transcripts for abstract ideas
- Concepts are rated by abstraction level (1-5)
- Supporting text passages are linked to concepts

### 4. Exploration
- Browse recording cards with metadata
- Explore concept cards and connections
- Search by semantic similarity

### 5. Knowledge Creation
- Select multiple concepts to combine
- Generate documents from connected ideas
- Build on existing knowledge iteratively

## 🎛️ Graph Schema

```
Recording ──HAS_TRANSCRIPT──► Transcript ──HAS_PART──► TranscriptPart
                                  │                         │
                                  │                         │
                              CONTAINS_CONCEPT      SUPPORTS_CONCEPT
                                  │                         │
                                  ▼                         ▼
                            IdeaConcept ◄─────RELATES_TO────► IdeaConcept
                                  │
                                  │
                             HAS_EMBEDDING
                                  │
                                  ▼
                              Embedding
```

## 🔧 Development

### Project Structure

```
soundbloom/
├── soundbloom/           # Main application code
│   ├── app.py           # Reflex web interface
│   ├── config.py        # Configuration settings
│   ├── database/        # Neo4j models and operations
│   └── processing/      # AI processing pipelines
├── data/                # Local data storage (gitignored)
│   ├── audio/          # Audio files
│   ├── transcripts/    # Transcription results
│   └── embeddings/     # Cached embeddings
├── requirements.txt     # Python dependencies
└── pyproject.toml      # Poetry configuration
```

### Adding New Features

1. **New AI Models**: Add to `processing/` directory
2. **Database Changes**: Update `database/models.py` and migrations
3. **UI Components**: Extend `app.py` with new Reflex components
4. **Processing Pipelines**: Create new pipeline classes in `processing/`

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a pull request

## 🤔 Thoughts & Questions

### Current Implementation Status
- ✅ Basic project structure and Poetry setup
- ✅ Reflex web interface foundation
- ✅ Neo4j graph schema design
- ✅ Whisper transcription pipeline
- ✅ Concept extraction framework
- ⚠️ **Python Version**: Need to upgrade to Python 3.10+ for modern packages
- 🔄 USB import functionality (in progress)
- 🔄 Embedding system (planned)
- 🔄 Full UI implementation (planned)

### Key Design Questions

1. **Concept Abstraction**: How do we balance concept specificity vs. reusability?
   - Current approach: 5-level abstraction scale
   - Alternative: Dynamic abstraction based on usage patterns

2. **Embedding Strategy**: Where to store high-dimensional vectors?
   - Option A: Neo4j with compressed embeddings
   - Option B: Dedicated vector DB (Pinecone, Weaviate, Qdrant)
   - Option C: Hybrid approach

3. **Local vs. Cloud Models**:
   - Whisper: Local (privacy + offline)
   - Concept extraction: Configurable (OpenAI API or local LLM)
   - Embeddings: Local (sentence-transformers)

4. **Scalability**: How to handle large collections?
   - Incremental processing
   - Batch operations
   - Caching strategies

### Next Development Priorities

1. **Immediate**: Upgrade Python environment to 3.10+
2. **Core Features**: Complete USB import and basic transcription
3. **AI Pipeline**: Integrate concept extraction with embeddings
4. **User Interface**: Build out the card-based exploration UI
5. **Performance**: Optimize for larger datasets

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OpenAI Whisper** for excellent speech recognition
- **Neo4j** for graph database capabilities
- **Reflex** for modern Python web development
- **Hugging Face** for transformer models and embeddings
Voice Note Discovery Platform
