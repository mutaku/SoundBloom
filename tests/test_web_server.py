#!/usr/bin/env python3
"""
Simple test web server to demonstrate SoundBloom LLM functionality.
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import urllib.parse
import requests
import datetime


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


class SoundBloomHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_main_page()
        elif self.path == '/test-concepts':
            self.test_concept_extraction()
        elif self.path == '/test-document':
            self.test_document_generation()
        else:
            self.send_404()

    def send_main_page(self):
        html = '''<!DOCTYPE html>
<html>
<head>
    <title>🌸 SoundBloom LLM Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .button { background: #007acc; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 10px; text-decoration: none; display: inline-block; }
        .button:hover { background: #005a9e; }
        .status { padding: 10px; margin: 10px 0; border-left: 4px solid #007acc; background: #e8f4f8; }
        .result { padding: 15px; margin: 10px 0; background: #f9f9f9; border-radius: 5px; font-family: monospace; white-space: pre-wrap; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌸 SoundBloom LLM Integration Test</h1>
        <p>This is a simple test server demonstrating the LLM functionality that will be integrated into SoundBloom.</p>
        
        <div class="status">
            <strong>Status:</strong> Ollama phi3:mini model is running and ready for testing.
        </div>
        
        <h2>🧪 Test Functions</h2>
        
        <a href="/test-concepts" class="button">🧠 Test Concept Extraction</a>
        <p>Extract key concepts from a sample transcript using the local LLM.</p>
        
        <a href="/test-document" class="button">📄 Test Document Generation</a>
        <p>Generate a strategic report from sample concepts using the local LLM.</p>
        
        <h2>🎯 Expected Integration</h2>
        <p>Once the Reflex compilation issue is resolved, this exact LLM functionality will power:</p>
        <ul>
            <li><strong>Concept Cards:</strong> AI-extracted concepts with confidence scores</li>
            <li><strong>Document Synthesis:</strong> Professional reports from selected concepts</li>
            <li><strong>Interactive Workspace:</strong> Drag-and-drop concept management</li>
            <li><strong>Graph Storage:</strong> Neo4j integration for concept relationships</li>
        </ul>
        
        <div class="status">
            <strong>Time:</strong> ''' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') + '''<br>
            <strong>Server:</strong> Running on http://localhost:8080
        </div>
    </div>
</body>
</html>'''
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())

    def test_concept_extraction(self):
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
        
        response = call_ollama_api(prompt)
        
        html = f'''<!DOCTYPE html>
<html>
<head>
    <title>🧠 Concept Extraction Test</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1000px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
        .back {{ color: #007acc; text-decoration: none; }}
        .result {{ padding: 15px; margin: 10px 0; background: #f9f9f9; border-radius: 5px; font-family: monospace; white-space: pre-wrap; font-size: 12px; }}
        .concept {{ padding: 10px; margin: 10px 0; border-left: 4px solid #28a745; background: #e8f5e8; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🧠 Concept Extraction Test Results</h1>
        <p><a href="/" class="back">← Back to Main</a></p>
        
        <h2>📝 Input Transcript:</h2>
        <div class="result">{transcript.strip()}</div>
        
        <h2>🤖 LLM Response:</h2>
        <div class="result">{response}</div>
        
        <h2>📋 Parsing Results:</h2>'''
        
        try:
            concepts = json.loads(response)
            if isinstance(concepts, list):
                html += f"<div class='concept'>✅ Successfully parsed {len(concepts)} concepts!</div>"
                for i, concept in enumerate(concepts, 1):
                    html += f'''
                    <div class="concept">
                        <h4>📝 Concept {i}: {concept.get('title', 'No title')}</h4>
                        <p><strong>Content:</strong> {concept.get('content', 'No content')}</p>
                        <p><strong>Keywords:</strong> {', '.join(concept.get('keywords', []))}</p>
                        <p><strong>Confidence:</strong> {concept.get('confidence', 'N/A')}</p>
                    </div>'''
            else:
                html += "<div class='concept'>❌ Response is not a valid array</div>"
        except Exception as e:
            html += f"<div class='concept'>❌ Failed to parse JSON: {str(e)}</div>"
        
        html += '''
    </div>
</body>
</html>'''
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())

    def test_document_generation(self):
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
        
        concept_summaries = []
        for c in concepts:
            summary = f"Title: {c['title']}\\nContent: {c['content']}"
            summary += f"\\nKeywords: {', '.join(c.get('keywords', []))}"
            concept_summaries.append(summary)
        
        concepts_text = "\\n\\n".join(concept_summaries)
        
        prompt = f"""
Create a brief strategic analysis report based on these concepts:

{concepts_text}

Generate a professional report with the following structure:
- Executive Summary
- Key Concepts Analysis  
- Synthesis and Recommendations
- Conclusion

Make it concise, insightful, and well-structured. Use markdown formatting.
The report should be approximately 200-400 words.
"""
        
        response = call_ollama_api(prompt)
        
        html = f'''<!DOCTYPE html>
<html>
<head>
    <title>📄 Document Generation Test</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1000px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
        .back {{ color: #007acc; text-decoration: none; }}
        .result {{ padding: 15px; margin: 10px 0; background: #f9f9f9; border-radius: 5px; font-family: monospace; white-space: pre-wrap; font-size: 12px; }}
        .document {{ padding: 20px; margin: 10px 0; border: 1px solid #ddd; border-radius: 5px; background: white; line-height: 1.6; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>📄 Document Generation Test Results</h1>
        <p><a href="/" class="back">← Back to Main</a></p>
        
        <h2>📋 Input Concepts:</h2>'''
        
        for i, concept in enumerate(concepts, 1):
            html += f'''
            <div class="result">
                Concept {i}: {concept['title']}
                Content: {concept['content']}
                Keywords: {', '.join(concept['keywords'])}
            </div>'''
        
        html += f'''
        <h2>📄 Generated Document:</h2>
        <div class="document">{response.replace(chr(10), '<br>')}</div>
        
        <h2>🤖 Raw LLM Response:</h2>
        <div class="result">{response}</div>
    </div>
</body>
</html>'''
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())

    def send_404(self):
        self.send_response(404)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'<h1>404 Not Found</h1>')


if __name__ == '__main__':
    server_address = ('', 8080)
    httpd = HTTPServer(server_address, SoundBloomHandler)
    print("🌸 SoundBloom LLM Test Server starting...")
    print("📱 Open http://localhost:8080 in your browser")
    print("🔍 Testing Ollama integration with phi3:mini model")
    print("⚠️  Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\\n🛑 Server stopped")
        httpd.server_close()