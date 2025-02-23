import requests
import msgpack

# Define the endpoint URL and headers
url = "http://localhost:8080/v1/tts"
headers = {
    "accept": "*/*",
    "Content-Type": "application/msgpack"
}

# Prepare the payload as a Python dictionary
payload = {
    "text": "Hello, my friend I want to tell you a story. The fox jumped over the road. Did you like my story?",
    "chunk_length": 2000,
    "format": "wav",
    "references": [],
    "reference_id": "test",
    "seed": None,
    "use_memory_cache": "off",
    "normalize": True,
    "streaming": False,
    "max_new_tokens": 1024,
    "top_p": 0.7,
    "repetition_penalty": 1.2,
    "temperature": 0.7,
}

# Encode the payload using msgpack
packed_payload = msgpack.packb(payload, use_bin_type=True)

# Make the POST request
response = requests.post(url, headers=headers, data=packed_payload)

# Check if the response was successful
if response.status_code == 200:
    # Save the binary content of the response as a .wav file
    with open("output.wav", "wb") as wav_file:
        wav_file.write(response.content)
    print("TTS WAV file saved as output.wav")
else:
    print("Error:", response.status_code, response.content)
