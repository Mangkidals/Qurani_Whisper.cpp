import os, uuid, subprocess
from flask import Flask, request, jsonify
from faster_whisper import WhisperModel

app = Flask(__name__)

model_size = os.environ.get("TRANSCRIBE_MODEL", "tiny")
model = WhisperModel(model_size, device="cpu", compute_type="int8")

def convert_to_wav16(in_path, out_path):
    subprocess.run([
        "ffmpeg","-y","-i",in_path,
        "-ar","16000","-ac","1","-f","wav",out_path
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

@app.route("/transcribe", methods=["POST"])
def transcribe():
    f = request.files.get("file")
    if not f:
        return jsonify({"error":"no file uploaded"}), 400
    tmp_in = f"/tmp/{uuid.uuid4().hex}_{f.filename}"
    tmp_wav = tmp_in + ".wav"
    f.save(tmp_in)
    convert_to_wav16(tmp_in, tmp_wav)
    segments, info = model.transcribe(tmp_wav, language="ar")
    text = " ".join([seg.text for seg in segments])
    return jsonify({"text": text.strip(), "lang": info.language})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
