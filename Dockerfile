# Ubuntu 24.04 ships Python 3.12. Stay on Ubuntu's own python3 rather than a python:*-slim image:
# some shelves in database/ are Berkeley DB files (dbm.ndbm), which Ubuntu's python3 can open.
FROM ubuntu:24.04 AS base

# Ubuntu marks its python3 as externally managed (PEP 668); this container is its only user.
ENV PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-dev python3-pip \
    ffmpeg python3-gdbm \
    && rm -rf /var/lib/apt/lists/*

# No JavaScript runtime (deno) on purpose, despite yt-dlp's "No supported JavaScript runtime" warning.
# Tested Nov 2026 with yt-dlp 2026.10.26: with deno, yt-dlp switches to the TVHTML5 client, whose
# stream urls YouTube answers with 403; without it, it picks a client whose streams play.

# Install Python dependencies
COPY ./requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# yt-dlp is deliberately not in requirements.txt: YouTube breaks old releases every few weeks.
# It is installed unpinned here, then upgraded again on every container start (docker-entrypoint.sh).
RUN pip3 install --no-cache-dir --upgrade "yt-dlp[default]"

# Copy test source files
FROM base AS test

COPY ./requirements-test.txt ./
RUN pip3 install -r requirements-test.txt

COPY ./pytest.ini ./
COPY ./GeorgeChampBot.py ./
COPY ./common ./common
COPY ./commands ./commands
COPY ./components ./components
COPY ./tests ./tests

# Fallback default; run-tests.sh overrides this to forward "$@" to pytest.
CMD ["python3", "-m", "pytest", "-v"]


# Copy source files
FROM base AS prod

COPY ./.env ./
COPY ./GeorgeChampBot.py ./
COPY ./common ./common
COPY ./commands ./commands
COPY ./components ./components
COPY ./docker-entrypoint.sh ./

# Run GeorgeChampBot (the entrypoint upgrades yt-dlp first)
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["python3", "./GeorgeChampBot.py"]
