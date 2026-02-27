import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma.service'; 
import { GuestModule } from './guest/guest.module';
import { AuthModule } from './auth/auth.module';

@Module({
  imports: [GuestModule, AuthModule],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
