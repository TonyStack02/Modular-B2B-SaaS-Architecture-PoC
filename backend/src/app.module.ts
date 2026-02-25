import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma.service'; 
import { GuestModule } from './guest/guest.module';

@Module({
  imports: [GuestModule],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
