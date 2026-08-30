FROM python:3.11-slim

WORKDIR /app

#This tells Python not to create .pyc (bytecode cache) files inside the 
#container
ENV PYTHONDONTWRITEBYTECODE=1

#It tells to print output immediately instead of buffering it
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python","manage.py","runserver","0.0.0.0:8080"]

