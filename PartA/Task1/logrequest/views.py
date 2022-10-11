from django.http import HttpResponse
from django.shortcuts import render
import datetime
from .models import Score
import json

# Create your views here.

def index(request):
    today = datetime.datetime.now().date()
    return render(request, "index.html")
def logview(request):
    if request.method == 'POST':
        # use request.body instead of request.data
        print(request.body)
        username = request.POST['username']
        m_score = int(request.POST['m_score'])+1
        Score.objects.create(User_ID =username , Score=m_score)
        print(m_score)

        return HttpResponse(username+"      "+str(m_score))