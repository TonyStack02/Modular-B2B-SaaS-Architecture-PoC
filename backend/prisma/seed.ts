// backend/prisma/seed.ts
/*
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🔥 INIZIO PROTOCOLLO DESERTO: Svuotamento totale del database in corso...');

  // 1. FOGLIE ESTREME (Transazioni, incassi e prenotazioni)
  await prisma.orderItem.deleteMany(); 
  await prisma.order.deleteMany();     
  await prisma.booking.deleteMany();

  // 2. RISORSE UMANE (Turni, ferie e dipendenti)
  await prisma.shift.deleteMany();
  await prisma.leaveRequest.deleteMany();
  await prisma.employee.deleteMany();

  // 3. CRM E MENU (Clienti in rubrica, pizze e categorie)
  await prisma.customer.deleteMany();
  await prisma.product.deleteMany();   
  await prisma.category.deleteMany();  

  // 4. IL LOCALE FISICO (Tavoli, porte, muri e sale)
  await prisma.resource.deleteMany();  
  await prisma.mapElement.deleteMany(); 
  await prisma.area.deleteMany();      
  
  // 5. UTENTI E PROPRIETARI (Nessuno potrà più fare login)
  await prisma.user.deleteMany();      
  
  // 6. IL NUCLEO (I Ristoranti stessi)
  await prisma.tenant.deleteMany();    

  console.log('🏜️ PROTOCOLLO COMPLETATO: Il database ora è un deserto. Non c\'è letteralmente più nulla.');
}

main()
  .catch((e) => {
    console.error('❌ Errore durante l\'apocalisse:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
  */

  // backend/prisma/seed.ts

import { PrismaClient } from '@prisma/client';
import { fakerIT as faker } from '@faker-js/faker';

const prisma = new PrismaClient();

// 🎯 IL BERSAGLIO: Inseriamo qui il tuo TenantID esatto
const TARGET_TENANT_ID = '231230c9-b0bd-49ab-87a9-699be3e4b2ad';

async function main() {
  console.log('🌱 Avvio l\'iniezione mirata dei dati per il ristorante Gio\'s...');

  // 1. Verifica di sicurezza: Controlliamo che il ristorante esista davvero
  const tenant = await prisma.tenant.findUnique({
    where: { id: TARGET_TENANT_ID }
  });

  if (!tenant) {
    console.error('❌ ERRORE: Ristorante non trovato nel database con questo ID!');
    return;
  }
  console.log(`✅ Trovato Ristorante: ${tenant.name}`);

  // 2. Crea le Aree (Sala e Dehor)
  const sala = await prisma.area.create({
    data: { name: 'Sala Interna', tenantId: TARGET_TENANT_ID },
  });
  const dehor = await prisma.area.create({
    data: { name: 'Dehor Estivo', tenantId: TARGET_TENANT_ID },
  });

  // 3. Crea i Tavoli (li salviamo in un array per usarli negli ordini)
  const tables: any[] = []; 
  
  // 10 Tavoli in Sala
  for (let i = 1; i <= 10; i++) {
    const table = await prisma.resource.create({
      data: {
        name: `Tavolo ${i}`,
        areaId: sala.id,
        tenantId: TARGET_TENANT_ID, 
        status: 'FREE', 
        capacity: faker.number.int({ min: 2, max: 6 }), 
      },
    });
    tables.push(table);
  }
  // 5 Tavoli nel Dehor
  for (let i = 1; i <= 5; i++) {
    const table = await prisma.resource.create({
      data: {
        name: `Tavolo Esterno ${i}`,
        areaId: dehor.id,
        tenantId: TARGET_TENANT_ID, 
        status: 'FREE',
        capacity: faker.number.int({ min: 2, max: 4 }),
      },
    });
    tables.push(table);
  }
  console.log('✅ Creati 15 Tavoli in 2 Aree');

  // 4. Crea il Menu
  const catPizze = await prisma.category.create({ data: { name: 'Pizze', tenantId: TARGET_TENANT_ID } });
  const catBibite = await prisma.category.create({ data: { name: 'Bibite', tenantId: TARGET_TENANT_ID } });

  await prisma.product.createMany({
    data: [
      { name: 'Margherita', price: 6.00, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID, description: 'Pomodoro, Mozzarella, Basilico' },
      { name: 'Diavola', price: 7.50, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID, description: 'Pomodoro, Mozzarella, Salame Piccante' },
      { name: 'Capricciosa', price: 8.50, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID, description: 'Carciofini, Funghi, Prosciutto, Olive' },
      { name: 'Coca Cola', price: 3.00, categoryId: catBibite.id, tenantId: TARGET_TENANT_ID },
      { name: 'Acqua Nat.', price: 1.50, categoryId: catBibite.id, tenantId: TARGET_TENANT_ID },
      { name: 'Birra Media', price: 5.00, categoryId: catBibite.id, tenantId: TARGET_TENANT_ID },
    ],
  });

  const allProducts = await prisma.product.findMany({ where: { tenantId: TARGET_TENANT_ID } });
  console.log('✅ Menu Creato (Pizze e Bibite)');

  // 5. Crea 20 Clienti finti nella rubrica
  const customers: any[] = []; 
  for (let i = 0; i < 20; i++) {
    const customer = await prisma.customer.create({
      data: {
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        phone: faker.phone.number(),
        tenantId: TARGET_TENANT_ID,
      },
    });
    customers.push(customer);
  }
  console.log('✅ Creati 20 Clienti nel CRM');

  // 6. Genera 200 Ordini storici sparsi negli ultimi 90 giorni
  console.log('⏳ Generazione di 200 ordini storici in corso...');

  for (let i = 0; i < 200; i++) {
    const randomTable = tables[Math.floor(Math.random() * tables.length)];
    const randomCustomer = Math.random() > 0.6 ? customers[Math.floor(Math.random() * customers.length)] : null;

    const orderDate = faker.date.recent({ days: 90 });
    const closedDate = new Date(orderDate.getTime() + faker.number.int({ min: 30, max: 120 }) * 60000);

    const numItems = faker.number.int({ min: 1, max: 4 });
    let calculatedTotal = 0;
    const orderItems: any[] = []; 

    for (let j = 0; j < numItems; j++) {
      const randomProduct = allProducts[Math.floor(Math.random() * allProducts.length)];
      const quantity = faker.number.int({ min: 1, max: 3 });

      calculatedTotal += Number(randomProduct.price) * quantity;

      orderItems.push({
        productId: randomProduct.id,
        quantity: quantity,
        unitPrice: randomProduct.price,
        notes: Math.random() > 0.8 ? 'Ben cotta' : null,
      });
    }

    // Salviamo l'ordine storico
    await prisma.order.create({
      data: {
        tenantId: TARGET_TENANT_ID,
        resourceId: randomTable.id,
        customerId: randomCustomer?.id,
        status: 'PAID',
        totalAmount: calculatedTotal,
        createdAt: orderDate,
        closedAt: closedDate,
        items: {
          create: orderItems,
        },
      },
    });

    // Aggiorniamo le statistiche se c'è un cliente in rubrica
    if (randomCustomer) {
      await prisma.customer.update({
        where: { id: randomCustomer.id },
        data: {
          totalOrders: { increment: 1 },
          totalSpent: { increment: calculatedTotal },
        },
      });
    }
  }

  console.log('✅ Generati 200 Ordini Storici con successo!');
  console.log('🚀 SEEDING COMPLETATO! Il tuo ristorante Gio\'s è pronto e pieno di dati.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });