// backend/src/map-element/dto/update-map-element.dto.ts

import { PartialType } from '@nestjs/mapped-types';
import { CreateMapElementDto } from './create-map-element.dto';

export class UpdateMapElementDto extends PartialType(CreateMapElementDto) {}