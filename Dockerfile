FROM node:20-slim

# ============================================================
# SYSTEM DEPENDENCIES
# ============================================================
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    openssh-client \
    gh \
    jq \
    # Build tools
    build-essential \
    gfortran \
    cmake \
    # R package dependencies
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    # sf, terra, spatial packages
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    # igraph
    libglpk-dev \
    # openssl
    libsodium-dev \
    # sqlite
    libsqlite3-dev \
    # nlopt for lme4/nloptr
    libnlopt-dev \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# PYTHON
# ============================================================
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    scipy \
    statsmodels \
    scikit-learn \
    jupyter \
    requests

# ============================================================
# R
# ============================================================
RUN apt-get update && apt-get install -y \
    r-base \
    r-base-dev \
    && rm -rf /var/lib/apt/lists/*

# Set CRAN mirror and increase timeout
RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"), timeout = 600)' >> /etc/R/Rprofile.site

# Install R packages (batched to avoid timeouts)
# Batch 1: Core data manipulation
RUN R -e "install.packages(c('tidyverse', 'data.table', 'haven', 'readxl', 'openxlsx', 'janitor', 'lubridate', 'here', 'fs', 'jsonlite', 'glue', 'httr2'))"

# Batch 2: Econometrics and causal inference
RUN R -e "install.packages(c('fixest', 'did', 'lfe', 'estimatr', 'sandwich', 'clubSandwich', 'plm', 'AER', 'ivreg', 'rdrobust', 'DRDID', 'synthdid', 'gsynth', 'Synth'))"

# Batch 3: Modeling
RUN R -e "install.packages(c('lme4', 'survival', 'caret', 'randomForest', 'MASS', 'Matrix', 'broom', 'car'))"

# Batch 4: Tables and reporting
RUN R -e "install.packages(c('modelsummary', 'stargazer', 'kableExtra', 'knitr', 'rmarkdown', 'tinytex'))"

# Batch 5: Visualization
RUN R -e "install.packages(c('patchwork', 'cowplot', 'ggrepel', 'ggthemes', 'viridis', 'scales', 'gridExtra'))"

# Batch 6: Parallel and utilities
RUN R -e "install.packages(c('parallel', 'foreach', 'doParallel', 'future', 'devtools', 'Rcpp', 'sf', 'terra'))"

# ============================================================
# CLAUDE CODE
# ============================================================
RUN npm install -g @anthropic-ai/claude-code

# ============================================================
# USER SETUP
# ============================================================
RUN useradd -m -s /bin/bash claude && \
    mkdir -p /home/claude/.claude && \
    mkdir -p /workspace && \
    chown -R claude:claude /home/claude /workspace

USER claude
WORKDIR /workspace

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["claude"]
