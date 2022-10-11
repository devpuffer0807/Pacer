# Functionalities

- You Can Add Student Information

- You Can Update Student Information

- You Can Delete Student Information

- You Can View Individual Student Information


# Project Setup Instructions
1) Git clone the repository 

2. Go To Project Directory

3. Create Virtual Environment
```
virtualenv env
```
4. Active Virtual Environment
```
env\scripts\activate
```
5. Install Requirements File
```
pip install -r requirements.txt
```
6. Make Migrations
```
py manage.py makemigrations
```
7. Migrate Database
```
py manage.py migrate
```
8. Run Project
```
py manage.py runserver
```