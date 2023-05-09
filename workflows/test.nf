def meta2 = ["id": "contrasts"]




ch= channel.from([[meta2, file(params.contrasts) ]] )
    .splitCsv(header : true, sep:',')
    .map { row -> tuple(row.variable, row.reference, row.target) }
    .view()


