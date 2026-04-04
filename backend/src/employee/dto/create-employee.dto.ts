// backend/src/employee/dto/create-employee.dto.ts

import { IsString, IsOptional, IsNumber, IsDateString, IsEnum } from 'class-validator';
import { EmployeeStatus } from '@prisma/client'; // Importiamo lo stato da Prisma

export class CreateEmployeeDto {
  // -- ANAGRAFICA --
  @IsString()
  firstName!: string;

  @IsString()
  lastName!: string;

  @IsString()
  jobRole!: string;

  @IsOptional() @IsString() email?: string;
  @IsOptional() @IsString() phone?: string;
  @IsOptional() @IsString() taxCode?: string;

  // -- SCADENZE E DATE --
  // IsDateString controlla che la data sia nel formato ISO corretto (es. 2026-06-30T00:00:00.000Z)
  @IsOptional() @IsDateString() hireDate?: string;
  @IsOptional() @IsDateString() contractEndDate?: string;
  @IsOptional() @IsDateString() haccpExpiry?: string;
  @IsOptional() @IsDateString() medicalCheckExpiry?: string;

  // -- COSTI E ORARI --
  @IsOptional() @IsNumber() hourlyWage?: number;
  @IsOptional() @IsNumber() weeklyContractHours?: number;

  // -- EMERGENZE E EXTRA --
  @IsOptional() @IsString() emergencyContact?: string;
  @IsOptional() @IsString() pinCode?: string;
  @IsOptional() @IsString() notes?: string;

  // -- SALDI --
  @IsOptional() @IsNumber() vacationDaysTotal?: number;
  @IsOptional() @IsNumber() sickDaysTotal?: number;

  // -- STATO --
  @IsOptional() @IsEnum(EmployeeStatus) status?: EmployeeStatus;
}