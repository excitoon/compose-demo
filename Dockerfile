FROM base

RUN sh -c "echo \"print('hello world')\" > app.py"

ENTRYPOINT ["python", "app.py"]
