FROM node:20-slim

RUN apt-get update && apt-get install -y \
    git curl wget openssh-client gh jq \
    build-essential gfortran cmake \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
    libglpk-dev libsodium-dev libsqlite3-dev libnlopt-dev \
    pandoc nano \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    ruby-full ruby-dev libyaml-dev libffi-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler jekyll

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages \
    pandas numpy matplotlib seaborn scipy \
    statsmodels scikit-learn jupyter requests

RUN apt-get update && apt-get install -y \
    r-base r-base-dev \
    && rm -rf /var/lib/apt/lists/*

RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"), timeout = 600)' >> /etc/R/Rprofile.site

RUN R -e "install.packages(c('tidyverse', 'data.table', 'haven', 'readxl', 'openxlsx', 'janitor', 'lubridate', 'here', 'fs', 'jsonlite', 'glue', 'httr2'))"

RUN R -e "install.packages(c('fixest', 'did', 'lfe', 'estimatr', 'sandwich', 'clubSandwich', 'plm', 'AER', 'ivreg', 'rdrobust', 'DRDID', 'synthdid', 'gsynth', 'Synth'))"

RUN R -e "install.packages(c('lme4', 'survival', 'caret', 'randomForest', 'MASS', 'Matrix', 'broom', 'car'))"

RUN R -e "install.packages(c('modelsummary', 'stargazer', 'kableExtra', 'knitr', 'rmarkdown', 'tinytex'))"

RUN R -e "install.packages(c('patchwork', 'cowplot', 'ggrepel', 'ggthemes', 'viridis', 'scales', 'gridExtra'))"

RUN R -e "install.packages(c('parallel', 'foreach', 'doParallel', 'future', 'devtools', 'Rcpp', 'sf', 'terra'))"

RUN npm install -g @anthropic-ai/claude-code && \
    which claude && \
    claude --version

RUN useradd -m -s /bin/bash claude && \
    mkdir -p /home/claude/.claude && \
    mkdir -p /home/claude/.config/gh && \
    mkdir -p /workspace && \
    chown -R claude:claude /home/claude /workspace

ENV EDITOR=nano
ENV GH_CONFIG_DIR=/home/claude/.config/gh

USER claude
WORKDIR /workspace
CMD ["claude"]
