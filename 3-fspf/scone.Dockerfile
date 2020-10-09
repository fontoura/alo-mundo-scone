FROM sconecuratedimages/public-apps:python-3.7.3-alpine3.10
COPY encrypted-files/programa.py /app/programa.py
COPY fspf/volume.fspf /fspf/volume.fspf
ENTRYPOINT [ "python3", "/app/programa.py" ]

