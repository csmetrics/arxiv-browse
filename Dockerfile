# arxiv/browse
#
# Defines the runtime for the arXiv browse service, which provides the main
# UIs for browse.

FROM python:3.10.8-buster
ARG git_commit

ENV PIPENV_VERBOSITY=-1
ENV LC_ALL en_US.utf8
ENV LANG en_US.utf8
ENV LOGLEVEL 40
#ENV FLASK_DEBUG 1

WORKDIR /opt/arxiv

# remove conflicting mariadb-libs from arxiv/base
#RUN yum remove -y mariadb-libs

# install MySQL
RUN apt-get -y install default-libmysqlclient-dev
#RUN yum install -y which mysql mysql-devel
#RUN pip install uwsgi

ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip install -U pip pipenv
RUN pip install "gunicorn==20.1.0"

ADD app.py /opt/arxiv/
ADD Pipfile /opt/arxiv/
ADD Pipfile.lock /opt/arxiv/
RUN pipenv sync

ENV PATH "/opt/arxiv:${PATH}"

ADD browse /opt/arxiv/browse
ADD tests /opt/arxiv/tests
ADD wsgi.py /opt/arxiv/

RUN echo $git_commit > /git-commit.txt

#ENV FLASK_APP /opt/arxiv/app.py

EXPOSE 8000
ENTRYPOINT ["pipenv", "run"]
#CMD ["uwsgi", "--ini", "/opt/arxiv/uwsgi.ini"]
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 wsgi:application
