import path from 'path';
import {
  loadPackageDefinition,
  ProtobufTypeDefinition,
  ServiceClientConstructor,
  GrpcObject,
} from '@grpc/grpc-js/build/src/make-client';
import { Server } from '@grpc/grpc-js/build/src/server';
import { ServerCredentials } from '@grpc/grpc-js/build/src/server-credentials';
import { loadSync } from '@grpc/proto-loader';

const PROTO_PATH = path.resolve(__dirname, '../../../proto');

const packageDefinition = loadSync(path.join(PROTO_PATH, 'greeter/service.proto'), {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
  includeDirs: [path.resolve(__dirname, '../../../')],
});

const protoDescriptor = loadPackageDefinition(packageDefinition);

const greeter = protoDescriptor.greeter;

function isGrpcObject(
  obj: GrpcObject | ServiceClientConstructor | ProtobufTypeDefinition,
): obj is GrpcObject {
  return !('service' in obj) && !('format' in obj);
}

function isServiceClientConstructor(
  obj: GrpcObject | ServiceClientConstructor | ProtobufTypeDefinition,
): obj is ServiceClientConstructor {
  return 'service' in obj;
}

function doSayHello(call: { request: { name: string } }, callback: Function) {
  callback(null, {
    message: 'Hello! ' + call.request.name,
  });
}

function getServer() {
  const server = new Server();
  if (isGrpcObject(greeter)) {
    const Greeter = greeter['GreeterService'];
    if (isServiceClientConstructor(Greeter)) {
      server.addService(Greeter.service, {
        sayHello: doSayHello,
      });
    }
  }
  return server;
}

const server = getServer();
server.bindAsync('0.0.0.0:9090', ServerCredentials.createInsecure(), () => {
  server.start();
});
