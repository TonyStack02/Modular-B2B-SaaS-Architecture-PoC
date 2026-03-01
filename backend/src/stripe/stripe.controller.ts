// backend/src/stripe/stripe.controller.ts

import { 
  Controller, Post, Headers, Req, BadRequestException, 
  Body, UseGuards 
} from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
// Usiamo un alias per la Request di Express per non fare confusione con NestJS
import { Request as ExpressRequest } from 'express'; 
import { StripeService } from './stripe.service';
import { OrderService } from '../order/order.service'; // <--- Importiamo il servizio ordini
import { CreatePaymentDto } from './dto/create-payment.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('stripe')
export class StripeController {
  constructor(
    private readonly stripeService: StripeService,
    private readonly orderService: OrderService, // <--- Iniezione: ora Stripe può parlare con gli Ordini
  ) {}

  @Post('create-intent')
  @UseGuards(JwtAuthGuard)
  async createIntent(@Body() dto: CreatePaymentDto) {
    // Passiamo sia l'importo che l'ID dell'ordine al servizio Stripe
    // Nota: Ho aggiunto 'orderId' al DTO (ricordati di aggiungerlo nel file DTO!)
    return this.stripeService.createPaymentIntent(dto.amount, dto.orderId);
  }

  @Post('webhook')
  async handleWebHook(
    @Headers('stripe-signature') sig: string,
    @Req() req: RawBodyRequest<ExpressRequest>, // Usiamo l'alias qui
  ) {
    if (!sig) throw new BadRequestException('Firma mancante!');

    if (!req.rawBody) {
      throw new BadRequestException('Corpo della richiesta mancante');
    }
    
    // 1. Verifichiamo che il messaggio arrivi davvero da Stripe
    let event;
    try {
      event = this.stripeService.verifyWebHook(req.rawBody, sig);
    } catch (err) {
      throw new BadRequestException(`Errore verifica Webhook: ${err.message}`);
    }

    // 2. Se il pagamento è riuscito, scatta la magia
    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object as any;
      
      // Recuperiamo il "post-it" (orderId) che abbiamo salvato nei metadata
      const orderId = paymentIntent.metadata?.orderId;

      if (orderId) {
        // AGGIORNIAMO IL DATABASE: L'ordine è ufficialmente pagato!
        await this.orderService.markAsPaid(orderId);
        console.log(`✅ Successo! L'ordine ${orderId} è stato segnato come PAID.`);
      } else {
        console.log('⚠️ Attenzione: Ricevuto pagamento senza orderId nei metadata.');
      }
    }

    // 3. Rispondiamo a Stripe con un bel "200 OK"
    return { received: true };
  }
}