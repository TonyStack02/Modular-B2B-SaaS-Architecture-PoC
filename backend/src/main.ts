import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  //Attiva la validazione globale
  app.useGlobalPipes(new ValidationPipe({
    whitelist : true, // Rimuove proprietà non definite nel DTO
    forbidNonWhitelisted : true, // Blocca la richiesta se ci sono proprietà extra
    transform : true //casta i tipi da string a number dove serve ad es.
  }));

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
