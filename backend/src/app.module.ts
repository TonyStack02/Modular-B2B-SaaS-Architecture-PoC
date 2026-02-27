import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma.service'; 
import { GuestModule } from './guest/guest.module';
import { AuthModule } from './auth/auth.module';
import { CatalogModule } from './catalog/catalog.module';
import { AreaModule } from './area/area.module';
import { ResourceModule } from './resource/resource.module';

@Module({
  imports: [GuestModule, AuthModule, CatalogModule, AreaModule, ResourceModule],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
