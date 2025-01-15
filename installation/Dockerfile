FROM continuumio/miniconda3

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8

# ======================================================================================================
# 1. Installing Dependencies
# ======================================================================================================
RUN apt-get update && apt-get install -y \
    gcc make git libcairo2-dev rpm2cpio cpio liblua5.3-dev lua5.3 \
    pkg-config rename tcl autoconf-archive locales libcjson-dev curl wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    r-base r-cran-ggplot2 r-cran-data.table r-cran-cowplot && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y python3.10 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install probe_design==0.2.45 \
    git+https://github.com/ggirelli/oligo-melting.git \
    prbdes==0.1.2


ENV PATH="/opt/conda/envs/base/bin:$PATH"

RUN conda install -y -c bioconda -c conda-forge bedtools=2.31.1 samtools && conda clean --all --yes
RUN echo "conda activate base" >> ~/.bashrc

# ======================================================================================================
# 2. Setting up custom directories
# ======================================================================================================
COPY hush /hush
COPY escafish /escafish
COPY oligoarrayaux /oligoarrayaux
COPY nHUSH /nHUSH
COPY fish-qc /fish-qc

# ======================================================================================================
# 3. Compile and install
# ======================================================================================================
RUN mkdir -p /usr/local/man/man1 /hush/bin /usr/local/bin /group /scratch

RUN cd /escafish && make install
RUN cd /hush && make all -B

ENV PATH="/hush/bin:${PATH}"

RUN cd /oligoarrayaux && chmod u+x configure && ./configure && make && make check && make install
ENV PKG_CONFIG_PATH="/nHUSH/pkg-config:${PKG_CONFIG_PATH}"

RUN cd /nHUSH && make && chmod u+x makedeb && ./makedeb && apt install ./nhush_*_amd64.deb
RUN cd /fish-qc && make && make install
ENV PATH="/usr/local/bin:${PATH}"

# ======================================================================================================
# 4. Setting the environment variables for paths
# ======================================================================================================
ENV PATH="/escafish/bin:/hush/bin:/nHUSH/bin:${PATH}"
ENV PATH="/oligoarrayaux/usr/share/:/oligoarrayaux/usr/bin/${PATH}"

# ======================================================================================================
# 5. Setting entry point
# ======================================================================================================
CMD ["/bin/bash"]

RUN echo "PKG_CONFIG_PATH is set to: $PKG_CONFIG_PATH"
