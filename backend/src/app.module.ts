import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma.service'; 
import { GuestModule } from './guest/guest.module';
import { AuthModule } from './auth/auth.module';
import { CatalogModule } from './catalog/catalog.module';
import { AreaModule } from './area/area.module';
import { ResourceModule } from './resource/resource.module';
import { OrderModule } from './order/order.module';
import { StripeModule } from './stripe/stripe.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { BookingModule } from './booking/booking.module';
import { MapElementModule } from './map-element/map-element.module';

@Module({
  imports: [GuestModule, AuthModule, CatalogModule, AreaModule, ResourceModule, OrderModule, StripeModule, DashboardModule, BookingModule, MapElementModule],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
