// backend/src/stripe/stripe.service.ts

import { Injectable, InternalServerErrorException } from '@nestjs/common';
import Stripe from 'stripe'; // Importiamo la libreria ufficiale

@Injectable()
export class StripeService {
  private stripe: Stripe;

  constructor() {
    const apiKey = process.env.STRIPE_SECRET_KEY;

    // Se la chiave è mancante, lanciamo un errore chiaro invece di far crashare tutto male
    if (!apiKey) {
      throw new InternalServerErrorException(
        'STRIPE_SECRET_KEY non trovata nel file .env',
      );
    }

    this.stripe = new Stripe(apiKey, {
      apiVersion: '2026-02-25.clover',
    });
  }

  // Metodo per creare l'intenzione di pagamento
  async createPaymentIntent( amount: number, orderId: string, currency: string = 'eur') {
    // Creiamo il PaymentIntent su Stripe
    const paymentIntent = await this.stripe.paymentIntents.create({
        // L'importo deve essere un intero in centesimi!
        amount: Math.round( amount * 100 ),
        currency: currency,
        automatic_payment_methods: { enabled: true }, // Abilita carte, Apple Pay, Google Pay, ecc.
        // Possiamo aggiungere metadati per ricordarci a quale ordine si riferisce
        metadata: { integration_check: 'accept_a_payment', orderId: orderId },
    });

    // Restituiamo il client_secret, l'unica cosa che serve davvero a Flutter
    return {
        clientSecret: paymentIntent.client_secret
    };
  }

  // Metodo per "decifrare" il messaggio di Stripe
  verifyWebHook(rawbody: Buffer, sig: string) {
    const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET; // Un altro segreto nel .env

    // Se il segreto non è configurato, non possiamo verificare il pagamento
    if (!endpointSecret) {
      throw new InternalServerErrorException(
        'STRIPE_WEBHOOK_SECRET non trovato nel file .env',
      );
    }

    try{
      // Stripe verifica se la firma (sig) corrisponde al contenuto (rawBody)
      return this.stripe.webhooks.constructEvent(
        rawbody,
        sig,
        endpointSecret,
      );
    } catch(err) {
      throw new Error( `Webhook error: ${err.message}` );
    }
  }

}