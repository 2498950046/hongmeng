@Entry
@Component
struct GradPage {
  @State numbers: string[] = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  build() {
    Grid() {
      ForEach(this.numbers, (item: string) => {
        GridItem() {
          Text(item)
        }
        .backgroundColor('#007DFF')
      })
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr')
    .columnsGap(5)
    .rowsGap(5)
    .height(300)
  }
}