from app import app
def test_home_and_api():
 c=app.test_client();assert c.get('/').status_code==200;assert len(c.get('/api/tasks').get_json())>=3
def test_task_lifecycle():
 c=app.test_client();t=c.post('/api/tasks',json={'title':'Test','course':'ICT725'}).get_json();assert c.patch(f"/api/tasks/{t['id']}",json={'completed':True}).get_json()['completed'];assert c.delete(f"/api/tasks/{t['id']}").status_code==204
