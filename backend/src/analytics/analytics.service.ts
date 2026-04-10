// backend/src/analytics/analytics.service.ts

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  async getDashboardStats(tenantId: string, startDate: string, endDate: string) {
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    // 1. Tiriamo su TUTTI gli ordini del periodo con i loro prodotti e categorie.
    // Essendo poche migliaia di righe, il server ci mette letteralmente 5 millisecondi.
    const orders = await this.prisma.order.findMany({
      where: {
        tenantId,
        status: 'PAID',
        createdAt: { gte: start, lte: end },
      },
      include: {
        items: {
          include: {
            product: { include: { category: true } }
          }
        }
      },
      orderBy: { createdAt: 'asc' }
    });

    let totalRevenue = 0;
    const totalOrders = orders.length;

    // Strutture per raggruppare i dati
    const dailyTrend: Record<string, { revenue: number; orders: number }> = {};
    const categorySplit: Record<string, number> = {};
    const productSales: Record<string, { name: string; qty: number }> = {};

    // 2. IL TRITACARNE: Maciniamo ogni singolo scontrino
    for (const order of orders) {
      const orderTotal = Number(order.totalAmount);
      totalRevenue += orderTotal;

      // Estraiamo la data (es. "2026-04-10")
      const dateStr = order.createdAt.toISOString().split('T')[0];

      // Riempiamo l'andamento giornaliero
      if (!dailyTrend[dateStr]) dailyTrend[dateStr] = { revenue: 0, orders: 0 };
      dailyTrend[dateStr].revenue += orderTotal;
      dailyTrend[dateStr].orders += 1;

      // Maciniamo le singole righe dello scontrino
      for (const item of order.items) {
        // Classifica Prodotti
        if (!productSales[item.productId]) {
          productSales[item.productId] = { name: item.product.name, qty: 0 };
        }
        productSales[item.productId].qty += item.quantity;

        // Classifica Categorie (Quanto incassa ogni categoria)
        const catName = item.product.category.name;
        if (!categorySplit[catName]) categorySplit[catName] = 0;
        categorySplit[catName] += (Number(item.unitPrice) * item.quantity);
      }
    }

    // 3. Impacchettiamo tutto per Flutter
    const averageOrderValue = totalOrders > 0 ? (totalRevenue / totalOrders) : 0;

    // Formattiamo il trend giornaliero
    const trendArray = Object.entries(dailyTrend).map(([date, data]) => ({
      date,
      revenue: data.revenue,
      orders: data.orders
    }));

    // Formattiamo la Top 5 Prodotti
    const topProductsArray = Object.values(productSales)
      .sort((a, b) => b.qty - a.qty)
      .slice(0, 5);

    // Formattiamo lo spaccato Categorie
    const categoryArray = Object.entries(categorySplit).map(([name, revenue]) => ({
      name,
      revenue
    }));

    // 🎁 Restituiamo il Mega-JSON
    return {
      kpi: { totalRevenue, totalOrders, averageOrderValue },
      charts: {
        dailyTrend: trendArray,
        topProducts: topProductsArray,
        categorySplit: categoryArray
      }
    };
  }
}