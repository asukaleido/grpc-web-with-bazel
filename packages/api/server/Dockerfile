FROM node:12.2.0-stretch-slim

COPY package.json /var/www/package.json
COPY packages/api/package.json /var/www/packages/app/package.json
COPY yarn.lock /var/www/yarn.lock

RUN curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version 1.16.0
RUN cd /var/www && ~/.yarn/bin/yarn --production && rm -rf ~/.npm

COPY packages/api/server/ /var/www/packages/api/server/
COPY proto/ /var/www/proto/

WORKDIR /var/www

ENTRYPOINT ["node", "--inspect=0.0.0.0:9229", "packages/api/server/index.js"]
EXPOSE 3000 9229
