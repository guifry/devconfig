import os

from dotenv import load_dotenv
from groq import Groq

load_dotenv()

SYSTEM_PROMPT = """Rewrite this prompt for an AI coding assistant. Rules:
- Fix typos/grammar from speech-to-text dictation
- Use XML tags to structure sections if beneficial
- Be concise, preserve technical meaning exactly
- British English
- Output ONLY the rewritten prompt, no commentary or explanation"""

client = Groq(api_key=os.getenv("GROQ_API_KEY"))


def reformat_prompt(text: str) -> str:
    if not text.strip():
        return text

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ],
        temperature=0.3,
        max_tokens=2048,
    )

    return response.choices[0].message.content or text
