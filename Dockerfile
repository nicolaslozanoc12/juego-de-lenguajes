FROM python:3.12-slim

WORKDIR /app
COPY backend ./backend
COPY contracts ./contracts

ENV PYTHONUNBUFFERED=1
EXPOSE 8765 8766

CMD ["python", "-m", "backend.main"]
