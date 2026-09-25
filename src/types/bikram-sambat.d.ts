declare module 'bikram-sambat' {
  export interface BikramDate {
    year: number
    month: number
    day: number
  }

  export interface GregDate {
    year: number
    month: number
    day: number
  }

  export function daysInMonth(year: number, month: number): number
  export function toBik(greg: Date | string | number): BikramDate
  export function toGreg(year: number, month: number, day: number): GregDate
  export function toBik_euro(greg: Date | string | number): string
  export function toBik_dev(greg: Date | string | number): string
  export function toBik_text(greg: Date | string | number): string
  export function toGreg_text(year: number, month: number, day: number): string
}
