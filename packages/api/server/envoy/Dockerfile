FROM envoyproxy/envoy:latest

COPY packages/api/server/envoy/envoy.yaml /etc/envoy/envoy.yaml

CMD /usr/local/bin/envoy -c /etc/envoy/envoy.yaml

EXPOSE 8080
