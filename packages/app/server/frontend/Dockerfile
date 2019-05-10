FROM nginx:1.13.11-alpine

ADD packages/app/server/frontend/nginx.conf /etc/nginx/nginx.conf

WORKDIR /etc/nginx

CMD ["nginx"]

EXPOSE 80
