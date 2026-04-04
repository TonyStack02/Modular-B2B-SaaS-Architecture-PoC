import { PartialType } from '@nestjs/mapped-types';
import { CreateMapElementDto } from './create-map-element.dto';

export class UpdateMapElementDto extends PartialType(CreateMapElementDto) {}