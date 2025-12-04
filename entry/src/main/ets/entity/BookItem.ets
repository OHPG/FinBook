import { BookHistory } from "./BookHistory"

export interface BookItem {

  id: string

  key: string

  name: string

  alias?: ResourceStr

  uri: string

  thumb?: string

  dir?: boolean

  date?: string

  size?: string

  history?: BookHistory

}