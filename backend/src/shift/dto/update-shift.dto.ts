// backend/src/shift/dto/update-shift.dto.ts

import { PartialType } from '@nestjs/mapped-types';
import { CreateShiftDto } from './create-shift.dto';

export class UpdateShiftDto extends PartialType(CreateShiftDto) {}
