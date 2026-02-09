from flask import Flask, request, jsonify
from threading import Lock

app = Flask(__name__)
jobs = {}  # {receiver: {"placeId": str, "jobId": str}}
lock = Lock()

@app.route('/add-job', methods=['POST'])
def add_job():
    data = request.get_json()
    receiver = data.get('receiver')
    placeId = data.get('placeId')
    jobId = data.get('jobId')

    if receiver and placeId and jobId:
        with lock:
            jobs[receiver.lower()] = {"placeId": placeId, "jobId": jobId}
        return jsonify({"success": True}), 200
    return jsonify({"success": False, "error": "Missing fields"}), 400

@app.route('/get-job', methods=['GET'])
def get_job():
    receiver = request.args.get('receiver')
    if receiver:
        with lock:
            job = jobs.get(receiver.lower())
            if job:
                del jobs[receiver.lower()]  # Tek seferlik al
                return jsonify(job), 200
    return jsonify({"success": False, "error": "No job found"}), 404

if __name__ == '__main__':
    app.run()
