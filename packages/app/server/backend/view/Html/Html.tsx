import fs from 'fs';
import * as React from 'react';

const manifest = JSON.parse(fs.readFileSync('./packages/app/client/bundle/manifest.json', 'utf8'));

type Props = {};

export const Html: React.FunctionComponent<Props> = ({ children }) => (
  <html lang={'ja'}>
    <head>
      <meta charSet="utf-8" />
      <meta httpEquiv="X-UA-Compatible" content="IE=edge,chrome=1" />
      <meta name="format-detection" content="telephone=no,address=no,email=no" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    </head>
    <body>
      <div id="app">{children}</div>
      <script src={`/assets/${manifest['vendor.js']}`} async={true} charSet="utf-8" />
      <script src={`/assets/${manifest['client.js']}`} async={true} charSet="utf-8" />
    </body>
  </html>
);
