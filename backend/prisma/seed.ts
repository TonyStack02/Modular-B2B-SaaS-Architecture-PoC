// backend/prisma/seed.ts

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Inizio il seeding del database...');

  // 1. Pulizia (Opzionale: cancella tutto se vuoi ripartire da zero, scommenta se serve)
  // await prisma.orderItem.deleteMany();
  // await prisma.order.deleteMany();
  // await prisma.product.deleteMany();
  // await prisma.category.deleteMany();
  // await prisma.resource.deleteMany();
  // await prisma.area.deleteMany();
  // await prisma.user.deleteMany();
  // await prisma.tenant.deleteMany();

  // 2. Crea il Ristorante (Tenant)
  const tenant = await prisma.tenant.create({
    data: {
      name: 'Pizzeria Da Mario',
      type: 'RESTAURANT',
    },
  });

  console.log(`✅ Creato Ristorante: ${tenant.name}`);

  // 3. Crea il Proprietario (Owner)
  const owner = await prisma.user.create({
    data: {
      email: 'mario@juicy.com',
      password: 'password123', // In produzione la cripteremo!
      name: 'Mario Rossi',
      role: 'OWNER',
      tenantId: tenant.id,
    },
  });

  console.log(`✅ Creato Owner: ${owner.email}`);

  // 4. Crea le Aree (Sala e Dehor)
  const sala = await prisma.area.create({
    data: { name: 'Sala Interna', tenantId: tenant.id },
  });
  const dehor = await prisma.area.create({
    data: { name: 'Dehor Estivo', tenantId: tenant.id },
  });

  // 5. Crea i Tavoli (Resources)
  // 10 Tavoli in Sala
  for (let i = 1; i <= 10; i++) {
    await prisma.resource.create({
      data: {
        name: `Tavolo ${i}`,
        capacity: 4,
        areaId: sala.id,
        status: 'FREE',
      },
    });
  }
  // 5 Tavoli nel Dehor
  for (let i = 1; i <= 5; i++) {
    await prisma.resource.create({
      data: {
        name: `Tavolo Esterno ${i}`,
        capacity: 2,
        areaId: dehor.id,
        status: 'FREE',
      },
    });
  }
  console.log('✅ Creati 15 Tavoli');

  // 6. Crea il Menu (Categorie e Prodotti)
  
  // Categoria Pizze
  const catPizze = await prisma.category.create({
    data: { name: 'Pizze', tenantId: tenant.id },
  });

  await prisma.product.createMany({
    data: [
      { name: 'Margherita', price: 6.00, categoryId: catPizze.id, tenantId: tenant.id, description: 'Pomodoro, Mozzarella, Basilico' },
      { name: 'Diavola', price: 7.50, categoryId: catPizze.id, tenantId: tenant.id, description: 'Pomodoro, Mozzarella, Salame Piccante' },
      { name: 'Capricciosa', price: 8.50, categoryId: catPizze.id, tenantId: tenant.id, description: 'Carciofini, Funghi, Prosciutto, Olive' },
    ],
  });

  // Categoria Bibite
  const catBibite = await prisma.category.create({
    data: { name: 'Bibite', tenantId: tenant.id },
  });

  await prisma.product.createMany({
    data: [
      { name: 'Coca Cola', price: 3.00, categoryId: catBibite.id, tenantId: tenant.id },
      { name: 'Acqua Nat.', price: 1.50, categoryId: catBibite.id, tenantId: tenant.id },
      { name: 'Birra Media', price: 5.00, categoryId: catBibite.id, tenantId: tenant.id },
    ],
  });

  console.log('✅ Menu Creato (Pizze e Bibite)');
  console.log('🚀 SEEDING COMPLETATO! Juicy è pronto.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });