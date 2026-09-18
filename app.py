from flask import Flask, jsonify, render_template, request

app = Flask(__name__)
tasks = [
 {"id":1,"title":"Complete mobile application report","course":"ICT725","priority":"High","date":"21 Sep 2026","completed":False},
 {"id":2,"title":"Review usability feedback","course":"ICT725","priority":"Medium","date":"24 Sep 2026","completed":False},
 {"id":3,"title":"Prepare presentation slides","course":"ICT725","priority":"Low","date":"28 Sep 2026","completed":True},
]
groups=[{"id":1,"name":"Mobile App Study Team","course":"ICT725","messages":2,"notes":1}]

@app.get("/")
def index(): return render_template("index.html")

@app.get("/api/tasks")
def get_tasks(): return jsonify(tasks)

@app.post("/api/tasks")
def add_task():
 data=request.get_json(force=True); task={"id":max([t["id"] for t in tasks],default=0)+1,"title":data.get("title") or "New study task","course":data.get("course") or "ICT725","priority":data.get("priority") or "Medium","date":data.get("date") or "30 Sep 2026","completed":False}; tasks.append(task); return jsonify(task),201

@app.patch("/api/tasks/<int:task_id>")
def patch_task(task_id):
 task=next((t for t in tasks if t["id"]==task_id),None)
 if not task:return jsonify(error="Task not found"),404
 task.update({k:v for k,v in request.get_json(force=True).items() if k in {"title","course","priority","date","completed"}}); return jsonify(task)

@app.delete("/api/tasks/<int:task_id>")
def remove_task(task_id):
 task=next((t for t in tasks if t["id"]==task_id),None)
 if not task:return jsonify(error="Task not found"),404
 tasks.remove(task); return "",204

@app.get("/api/groups")
def get_groups(): return jsonify(groups)

@app.post("/api/groups")
def add_group():
 data=request.get_json(force=True); group={"id":max([g["id"] for g in groups],default=0)+1,"name":data.get("name") or "New Study Group","course":data.get("course") or "ICT725","messages":0,"notes":0}; groups.append(group); return jsonify(group),201

if __name__=="__main__": app.run(host="0.0.0.0",port=5000,debug=True)
