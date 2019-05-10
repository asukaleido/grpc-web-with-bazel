import React from 'react';
import ReactDOM from 'react-dom';

import { FooComponent } from '@grpc-web-with-bazel/foundation/components/FooComponent';
import { $root } from '@grpc-web-with-bazel/proto';

ReactDOM.hydrate(<FooComponent />, document.getElementById('app'));

console.log($root.greeter.HelloRequest.create({ user: { name: 'hoge' } }));
