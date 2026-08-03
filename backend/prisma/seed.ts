// backend/prisma/seed.ts

import { PrismaClient } from '@prisma/client';
import { fakerIT as faker } from '@faker-js/faker';

// Inizializziamo il client di Prisma
const prisma = new PrismaClient();

// Il tuo ID fisso per non perdere i riferimenti con il frontend
const TARGET_TENANT_ID = 'b6d3af02-fe8e-422c-ad1e-0172d788fd40';

// ==========================================
// 🧹 FUNZIONE 1: L'IDROPULITRICE (Svuota Tutto)
// ==========================================
async function svuotaTutto() {
  console.log('🔥 AVVIO PULIZIA: Svuotamento totale del database in corso...');

  // 1. Dati operativi (Checklist, Ordini, Prenotazioni)
  // Eliminiamo per prime le tabelle "figlie" che dipendono dalle altre
  await prisma.checklistTaskResult.deleteMany({ where: { instance: { tenantId: TARGET_TENANT_ID } } });
  await prisma.checklistInstance.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });
  await prisma.checklistTaskTemplate.deleteMany({ where: { template: { tenantId: TARGET_TENANT_ID } } });
  await prisma.checklistTemplate.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });
  
  await prisma.orderItem.deleteMany({ where: { order: { tenantId: TARGET_TENANT_ID } } }); 
  await prisma.order.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });     
  await prisma.booking.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });

  // 2. Risorse Umane
  await prisma.shift.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });
  await prisma.leaveRequest.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });
  await prisma.employee.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });

  // 3. CRM e Menu
  await prisma.customer.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });
  await prisma.product.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });   
  await prisma.category.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });  

  // 4. Locale Fisico
  await prisma.resource.deleteMany({ where: { tenantId: TARGET_TENANT_ID } });  
  await prisma.mapElement.deleteMany({ where: { tenantId: TARGET_TENANT_ID } }); 
  await prisma.area.deleteMany({ where: { tenantId: TARGET_TENANT_ID } }); 

  console.log('✨ Database pulito a specchio.');
}

// ==========================================
// 🏗️ FUNZIONE 2: LA FENICE (Riempe Tutto)
// ==========================================
async function riempiTutto() {
  console.log('🏗️ AVVIO RICOSTRUZIONE: Iniezione dei dati in corso...');

  // 0. Assicuriamoci che il Ristorante (Tenant) esista
  const tenant = await prisma.tenant.upsert({
    where: { id: TARGET_TENANT_ID },
    update: {}, // Se esiste già non lo tocca
    create: {
      id: TARGET_TENANT_ID,
      name: "Ristorante di Gioele",
      type: "RESTAURANT"
    }
  });

  // 1. RICOSTRUZIONE MAPPA E AREE
  const salaPrincipale = await prisma.area.create({ data: { name: 'Sala Principale', tenantId: TARGET_TENANT_ID, positionX: 0, positionY: 0, width: 800, height: 600 } });
  const terrazza = await prisma.area.create({ data: { name: 'Terrazza Estiva', tenantId: TARGET_TENANT_ID, positionX: 850, positionY: 0, width: 400, height: 600 } });
  const privee = await prisma.area.create({ data: { name: 'Privée VIP', tenantId: TARGET_TENANT_ID, positionX: 0, positionY: 650, width: 500, height: 300 } });

  await prisma.mapElement.createMany({
    data: [
      { type: 'WALL', positionX: 0, positionY: 0, width: 800, height: 20, tenantId: TARGET_TENANT_ID },
      { type: 'DOOR', positionX: 400, positionY: 600, width: 100, height: 20, tenantId: TARGET_TENANT_ID },
      { type: 'TEXT', text: 'Ingresso Principale', positionX: 400, positionY: 630, width: 150, height: 30, tenantId: TARGET_TENANT_ID },
      { type: 'TEXT', text: 'Cassa', positionX: 50, positionY: 50, width: 100, height: 30, tenantId: TARGET_TENANT_ID },
      { type: 'TEXT', text: 'Bancone Bar', positionX: 600, positionY: 50, width: 150, height: 30, tenantId: TARGET_TENANT_ID },
    ]
  });

  const tables: any[] = [];
  for (let i = 1; i <= 12; i++) {
    const table = await prisma.resource.create({ data: { name: `Tavolo ${i}`, areaId: salaPrincipale.id, tenantId: TARGET_TENANT_ID, capacity: faker.number.int({ min: 2, max: 6 }) } });
    tables.push(table);
  }
  for (let i = 1; i <= 8; i++) {
    const table = await prisma.resource.create({ data: { name: `Esterno ${i}`, areaId: terrazza.id, tenantId: TARGET_TENANT_ID, capacity: faker.number.int({ min: 2, max: 4 }) } });
    tables.push(table);
  }
  for (let i = 1; i <= 5; i++) {
    const table = await prisma.resource.create({ data: { name: `VIP ${i}`, areaId: privee.id, tenantId: TARGET_TENANT_ID, capacity: faker.number.int({ min: 4, max: 10 }) } });
    tables.push(table);
  }

  // 2. CREAZIONE MENU GIGANTE
  const catAntipasti = await prisma.category.create({ data: { name: 'Antipasti', tenantId: TARGET_TENANT_ID } });
  const catPrimi = await prisma.category.create({ data: { name: 'Primi Piatti', tenantId: TARGET_TENANT_ID } });
  const catSecondi = await prisma.category.create({ data: { name: 'Secondi di Carne', tenantId: TARGET_TENANT_ID } });
  const catPizze = await prisma.category.create({ data: { name: 'Pizze Gourmet', tenantId: TARGET_TENANT_ID } });
  const catDolci = await prisma.category.create({ data: { name: 'Dolci', tenantId: TARGET_TENANT_ID } });
  const catBevande = await prisma.category.create({ data: { name: 'Beverage & Bar', tenantId: TARGET_TENANT_ID } });

  await prisma.product.createMany({
    data: [
      { name: 'Tagliere Imperiale', price: 18.00, categoryId: catAntipasti.id, tenantId: TARGET_TENANT_ID, description: 'Salumi, formaggi, miele, noci' },
      { name: 'Bruschette Miste', price: 8.00, categoryId: catAntipasti.id, tenantId: TARGET_TENANT_ID },
      { name: 'Tartare di Manzo', price: 14.50, categoryId: catAntipasti.id, tenantId: TARGET_TENANT_ID, description: 'Con tuorlo marinato e tartufo' },
      { name: 'Fiori di Zucca Fritti', price: 9.00, categoryId: catAntipasti.id, tenantId: TARGET_TENANT_ID },
      { name: 'Spaghettoni Carbonara', price: 13.00, categoryId: catPrimi.id, tenantId: TARGET_TENANT_ID, description: 'Guanciale croccante, pecorino romano, pepe nero' },
      { name: 'Paccheri al Ragù di Cinghiale', price: 15.50, categoryId: catPrimi.id, tenantId: TARGET_TENANT_ID },
      { name: 'Risotto Zafferano e Salsiccia', price: 14.00, categoryId: catPrimi.id, tenantId: TARGET_TENANT_ID },
      { name: 'Ravioli Burro e Salvia', price: 12.00, categoryId: catPrimi.id, tenantId: TARGET_TENANT_ID },
      { name: 'Tagliata di Fassona', price: 22.00, categoryId: catSecondi.id, tenantId: TARGET_TENANT_ID, description: 'Rucola, grana, pomodorini' },
      { name: 'Filetto al Pepe Verde', price: 25.00, categoryId: catSecondi.id, tenantId: TARGET_TENANT_ID },
      { name: 'Grigliata Mista', price: 28.00, categoryId: catSecondi.id, tenantId: TARGET_TENANT_ID },
      { name: 'Regina Margherita', price: 7.50, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID, description: 'Mozzarella di Bufala DOP' },
      { name: 'Diavola', price: 8.50, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID },
      { name: 'Pistacchiosa', price: 14.00, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID, description: 'Mortadella, pesto di pistacchio, burrata' },
      { name: 'Tartufata', price: 15.50, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID },
      { name: 'Calzone Classico', price: 9.00, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID },
      { name: 'Salsiccia e Friarielli', price: 10.00, categoryId: catPizze.id, tenantId: TARGET_TENANT_ID },
      { name: 'Tiramisù della Nonna', price: 6.50, categoryId: catDolci.id, tenantId: TARGET_TENANT_ID },
      { name: 'Cheesecake Frutti Rossi', price: 7.00, categoryId: catDolci.id, tenantId: TARGET_TENANT_ID },
      { name: 'Panna Cotta al Caramello', price: 6.00, categoryId: catDolci.id, tenantId: TARGET_TENANT_ID },
      { name: 'Cannolo Scomposto', price: 7.50, categoryId: catDolci.id, tenantId: TARGET_TENANT_ID },
      { name: 'Acqua Naturale 1L', price: 2.50, categoryId: catBevande.id, tenantId: TARGET_TENANT_ID },
      { name: 'Acqua Frizzante 1L', price: 2.50, categoryId: catBevande.id, tenantId: TARGET_TENANT_ID },
      { name: 'Coca Cola', price: 3.50, categoryId: catBevande.id, tenantId: TARGET_TENANT_ID },
      { name: 'Ichnusa Non Filtrata', price: 5.50, categoryId: catBevande.id, tenantId: TARGET_TENANT_ID },
      { name: 'Calice di Chianti', price: 6.50, categoryId: catBevande.id, tenantId: TARGET_TENANT_ID },
      { name: 'Bottiglia Barolo', price: 45.00, categoryId: catBevande.id, tenantId: TARGET_TENANT_ID },
      { name: 'Caffè Espresso', price: 1.50, categoryId: catBevande.id, tenantId: TARGET_TENANT_ID },
      { name: 'Amaro del Capo', price: 4.00, categoryId: catBevande.id, tenantId: TARGET_TENANT_ID },
    ]
  });
  const allProducts = await prisma.product.findMany({ where: { tenantId: TARGET_TENANT_ID } });

  // 3. HR - STAFF, TURNI E FERIE
  const roles = ['Cameriere', 'Cuoco', 'Capo Sala', 'Lavapiatti', 'Bartender', 'Pizzaiolo'];
  const employees: any[] = [];
  for (let i = 0; i < 12; i++) {
    const employee = await prisma.employee.create({
      data: {
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        email: faker.internet.email(),
        phone: faker.phone.number(),
        taxCode: faker.string.alphanumeric(16).toUpperCase(),
        jobRole: faker.helpers.arrayElement(roles),
        hourlyWage: faker.number.float({ min: 8, max: 18, fractionDigits: 2 }),
        weeklyContractHours: faker.helpers.arrayElement([20, 30, 40]),
        pinCode: faker.string.numeric(4),
        status: faker.helpers.arrayElement(['ACTIVE', 'ACTIVE', 'ACTIVE', 'ON_LEAVE']), 
        vacationDaysTotal: faker.number.float({ min: 0, max: 20, fractionDigits: 1 }),
        tenantId: TARGET_TENANT_ID,
      }
    });
    employees.push(employee);

    for(let s=0; s<10; s++) {
      const shiftStart = faker.date.recent({ days: 30 });
      const shiftEnd = new Date(shiftStart.getTime() + faker.number.int({ min: 6, max: 9 }) * 60 * 60 * 1000); 
      await prisma.shift.create({
        data: {
          startTime: shiftStart,
          endTime: shiftEnd,
          notes: Math.random() > 0.8 ? 'Turno extra coperto' : null,
          employeeId: employee.id,
          tenantId: TARGET_TENANT_ID,
        }
      });
    }

    if (Math.random() > 0.6) {
      await prisma.leaveRequest.create({
        data: {
          type: faker.helpers.arrayElement(['VACATION', 'SICK', 'PERMIT']),
          startDate: faker.date.soon({ days: 10 }),
          endDate: faker.date.soon({ days: 15 }),
          status: faker.helpers.arrayElement(['PENDING', 'APPROVED', 'REJECTED']),
          employeeId: employee.id,
          tenantId: TARGET_TENANT_ID,
        }
      });
    }
  }

  // 4. CRM E PRENOTAZIONI
  const customers: any[] = [];
  for (let i = 0; i < 80; i++) {
    const customer = await prisma.customer.create({
      data: {
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        phone: faker.phone.number(),
        email: faker.internet.email(),
        notes: Math.random() > 0.8 ? 'Ottimo cliente, ama il Barolo' : null,
        tenantId: TARGET_TENANT_ID,
      },
    });
    customers.push(customer);
  }

  for (let i = 0; i < 60; i++) {
    const isFuture = Math.random() > 0.4;
    const bookingDate = isFuture ? faker.date.soon({ days: 20 }) : faker.date.recent({ days: 60 });
    const c = faker.helpers.arrayElement(customers);
    await prisma.booking.create({
      data: {
        dateTime: bookingDate,
        guests: faker.number.int({ min: 2, max: 12 }),
        status: isFuture ? faker.helpers.arrayElement(['CONFIRMED', 'PENDING']) : 'COMPLETED',
        customerName: `${c.firstName} ${c.lastName}`,
        customerPhone: c.phone,
        customerId: c.id,
        resourceId: faker.helpers.arrayElement(tables).id,
        tenantId: TARGET_TENANT_ID,
      }
    });
  }

  // 5. IL TESORO (600 SCONTRINI STORICI)
  for (let i = 0; i < 600; i++) {
    const randomTable = faker.helpers.arrayElement(tables);
    const randomCustomer = Math.random() > 0.4 ? faker.helpers.arrayElement(customers) : null;
    const orderDate = faker.date.recent({ days: 180 });
    const closedDate = new Date(orderDate.getTime() + faker.number.int({ min: 45, max: 180 }) * 60000);

    const numItems = faker.number.int({ min: 2, max: 8 });
    let calculatedTotal = 0;
    const orderItems: any[] = [];

    for (let j = 0; j < numItems; j++) {
      const randomProduct = faker.helpers.arrayElement(allProducts);
      const quantity = faker.number.int({ min: 1, max: 5 }); 
      calculatedTotal += Number(randomProduct.price) * quantity;

      orderItems.push({
        productId: randomProduct.id,
        quantity: quantity,
        unitPrice: randomProduct.price,
        notes: Math.random() > 0.9 ? 'Allergia Lattosio' : null,
      });
    }

    await prisma.order.create({
      data: {
        tenantId: TARGET_TENANT_ID,
        resourceId: randomTable.id,
        customerId: randomCustomer?.id,
        status: 'PAID',
        totalAmount: calculatedTotal,
        createdAt: orderDate,
        closedAt: closedDate,
        items: { create: orderItems },
      },
    });

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

  console.log('🎉 DATI INIETTATI CON SUCCESSO!');
}

// ==========================================
// 🕹️ IL PANNELLO DI CONTROLLO PRINCIPALE
// Commenta o scommenta le righe qui sotto per decidere cosa far fare allo script.
// ==========================================
async function main() {
  
  // 1. Svuota completamente il database (utile se hai dati vecchi incasinati)
  //await svuotaTutto();

  // 2. Riempi il database con tutti i dati finti (Mappa, Ordini, Dipendenti, ecc.)
  await riempiTutto();
  
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    // Chiudiamo la connessione al database
    await prisma.$disconnect();
  });