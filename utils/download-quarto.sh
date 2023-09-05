QUARTO_VERSION=$(/bin/cat .quarto-version)
QUARTOPATH=./.quarto-cli
wget \
  -P ${QUARTOPATH} \
  https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-macos.tar.gz
mkdir -p ${QUARTOPATH}/quarto-${QUARTO_VERSION}-macos
tar -xf ${QUARTOPATH}/quarto-${QUARTO_VERSION}-macos.tar.gz -C ${QUARTOPATH}/quarto-${QUARTO_VERSION}-macos
rm ${QUARTOPATH}/quarto-${QUARTO_VERSION}-macos.tar.gz
