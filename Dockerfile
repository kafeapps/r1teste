FROM ubuntu:latest
LABEL authors="sievers"

ENTRYPOINT ["top", "-b"]

# Set the base image to use cypress/browsers
FROM cypress/browsers:latest as cypress_base
#
FROM python:3.10

COPY --from=cypress_base /usr/local/bin /usr/local/bin
COPY --from=cypress_base /usr/local/lib /usr/local/lib

#
WORKDIR /code

#
COPY ./requirements.txt /code/requirements.txt

# Adicionar chave do repositório do Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

# Adicionar repositório do Google Chrome
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# Instalar Google Chrome
RUN apt-get update && apt-get install -y \
    google-chrome-stable \
    --no-install-recommends

# Limpar cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*


# Set the environment variable for the path
ENV PATH /home/root/.local/bin:${PATH}

# Update the package list and install necessary packages
RUN apt-get update && apt-get install -y python3-pip

#
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

#
COPY ./main.py /code/

CMD uvicorn main:app --host 0.0.0.0 --port $PORT
#CMD ["fastapi", "run", "main.py", "--port", "80"]
