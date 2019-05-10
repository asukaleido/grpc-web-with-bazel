import path from 'path';
import fastify from 'fastify';
import fastifyStatic from 'fastify-static';
import React from 'react';
import ReactDOMServer from 'react-dom/server';

import { FooComponent } from '@grpc-web-with-bazel/foundation/components/FooComponent';

import { Html } from './view/Html';

const server = fastify({
  logger: true,
});

server.register(fastifyStatic, {
  root: path.join(__dirname, '../../client/bundle'),
  prefix: '/assets/',
});

server.get('*', (_, reply) => {
  const res = reply.res;
  res.write('<!doctype html>');
  ReactDOMServer.renderToNodeStream(
    <Html>
      <FooComponent />
    </Html>,
  ).pipe(res);
});

server.listen(3000, '0.0.0.0', (err) => {
  if (err) {
    throw err;
  }
});
