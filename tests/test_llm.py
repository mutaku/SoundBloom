#!/usr/bin/env python3
"""
Test script to verify Ollama integration is working.
"""

import requests
import json


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


def test_concept_extraction():
    """Test concept extraction with LLM."""
    print("🧪 Testing Concept Extraction with LLM")
    print("=" * 50)
    
    # Mock transcript
    transcript = """
    In today's discussion, we covered several important topics about artificial intelligence.
    First, we talked about the rapid advancement in AI technology, including new developments 
    in machine learning algorithms. Second, we discussed the challenges facing innovation 
    in the tech industry, particularly around data privacy and ethical AI development.
    Finally, we examined market trends and how companies are adapting to stay competitive
    in this rapidly evolving landscape.
    """
    
    prompt = f"""
    Analyze this transcript and extract 3 key concepts in JSON format:
    
    Transcript: {transcript.strip()}
    
    Return exactly 3 concepts as valid JSON array with this format:
    [
        {{
            "id": "concept_1",
            "title": "Brief Title",
            "content": "Detailed summary of the concept",
            "source": "transcript",
            "confidence": 0.85,
            "keywords": ["keyword1", "keyword2", "keyword3"]
        }}
    ]
    
    Important: Return ONLY the JSON array, no other text.
    """
    
    print("🤖 Calling Ollama API...")
    response = call_ollama_api(prompt)
    print(f"📤 Response length: {len(response)} characters")
    print("📋 Raw response:")
    print("-" * 30)
    print(response[:500] + "..." if len(response) > 500 else response)
    print("-" * 30)
    
    try:
        concepts = json.loads(response)
        print(f"✅ Successfully parsed {len(concepts)} concepts!")
        for i, concept in enumerate(concepts, 1):
            print(f"\n📝 Concept {i}: {concept.get('title', 'No title')}")
            print(f"   Content: {concept.get('content', 'No content')[:100]}...")
            print(f"   Keywords: {concept.get('keywords', [])}")
    except Exception as e:
        print(f"❌ Failed to parse JSON: {e}")


def test_document_generation():
    """Test document generation with LLM."""
    print("\n\n📄 Testing Document Generation with LLM")
    print("=" * 50)
    
    # Mock concepts
    concepts = [
        {
            "title": "AI Technology Trends",
            "content": "Discussion about current AI developments and future implications",
            "keywords": ["AI", "technology", "future", "development"]
        },
        {
            "title": "Innovation Challenges",
            "content": "Key challenges facing innovation in the tech industry",
            "keywords": ["innovation", "challenges", "industry", "obstacles"]
        }
    ]
    
    # Prepare concepts for LLM
    concept_summaries = []
    for c in concepts:
        summary = f"Title: {c['title']}\nContent: {c['content']}"
        summary += f"\nKeywords: {', '.join(c.get('keywords', []))}"
        concept_summaries.append(summary)
    
    concepts_text = "\n\n".join(concept_summaries)
    
    prompt = f"""
Create a comprehensive strategic analysis report based on these concepts:

{concepts_text}

Generate a professional report with the following structure:
- Executive Summary
- Key Concepts Analysis  
- Synthesis and Recommendations
- Conclusion

Make it insightful, actionable, and well-structured. Use markdown formatting.
The report should be approximately 300-500 words.
"""
    
    print("🤖 Calling Ollama API for document generation...")
    response = call_ollama_api(prompt)
    print(f"📤 Response length: {len(response)} characters")
    print("📋 Generated document:")
    print("-" * 50)
    print(response)
    print("-" * 50)


if __name__ == "__main__":
    print("🌸 SoundBloom LLM Integration Test")
    print("==================================")
    
    # Test concept extraction
    test_concept_extraction()
    
    # Test document generation
    test_document_generation()
    
    print("\n✨ Testing complete!")