FROM ubuntu:latest
LABEL authors="sievers"

ENTRYPOINT ["top", "-b"]

# Base image com navegadores do Cypress
FROM cypress/browsers:latest as cypress_base

# Usar Python 3.10
FROM python:3.10

# Copiar os binários do Cypress
COPY --from=cypress_base /usr/local/bin /usr/local/bin
COPY --from=cypress_base /usr/local/lib /usr/local/lib

# Definir o diretório de trabalho
WORKDIR /code

# Copiar o arquivo de requisitos
COPY ./requirements.txt /code/requirements.txt

# Adicionar chave do repositório do Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

# Adicionar repositório do Google Chrome
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# Instalar Google Chrome e outras dependências necessárias
RUN apt-get update && apt-get install -y \
    google-chrome-stable \
    xvfb \
    wget \
    unzip \
    --no-install-recommends

# Limpar cache do apt-get
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar o pip e as dependências do Python
RUN apt-get update && apt-get install -y python3-pip
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Instalar o WebDriver Manager e baixar o chromedriver
RUN pip install --no-cache-dir webdriver-manager
RUN wget -q https://chromedriver.storage.googleapis.com/$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE)/chromedriver_linux64.zip \
    && unzip chromedriver_linux64.zip -d /usr/local/bin/ \
    && rm chromedriver_linux64.zip \
    && chmod +x /usr/local/bin/chromedriver

# Copiar o arquivo principal do código
COPY ./main.py /code/

# Comando para rodar a aplicação FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
