// backend/src/main.ts

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { join } from 'path';
import * as express from 'express';

async function bootstrap() {
  // Configuriamo l'app per catturare il body "grezzo"
  const app = await NestFactory.create(AppModule , {
    rawBody: true,
  });

  //Attiva la validazione globale
  app.useGlobalPipes(new ValidationPipe({
    whitelist : true, // Rimuove proprietà non definite nel DTO
    forbidNonWhitelisted : true, // Blocca la richiesta se ci sono proprietà extra
    transform : true //casta i tipi da string a number dove serve ad es.
  }));

  // Rendiamo la cartella uploads accessibile via browser/app
  // Es: http://localhost:3000/uploads/products/foto.jpg
  app.use('/uploads', express.static(join(__dirname, '..', 'uploads')));

  app.enableCors();
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
