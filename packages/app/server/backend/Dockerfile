FROM node:12.2.0-stretch-slim

COPY package.json /var/www/package.json
COPY packages/app/package.json /var/www/packages/app/package.json
COPY packages/foundation/package.json /var/www/packages/foundation/package.json
COPY packages/proto/package.json /var/www/packages/proto/package.json
COPY yarn.lock /var/www/yarn.lock

RUN curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version 1.16.0
RUN cd /var/www && ~/.yarn/bin/yarn --production && rm -rf ~/.npm

COPY packages/app/ /var/www/packages/app/
COPY packages/foundation/ /var/www/packages/foundation/
COPY packages/proto/ /var/www/proto/foundation/

WORKDIR /var/www

ENTRYPOINT ["node", "--inspect=0.0.0.0:9229", "packages/app/server/backend/index.js"]
EXPOSE 3000 9229
