module namespace score = "artel2018";

declare function score:table ($board)
{
  let $data := $board//values
  let $first := score:first($board)
  let $second := score:second($board)
  let $self_score := 
    for $i in $data
    return $i/child::*[@имя/data()=$i/child::*[@имя/data() = "ФИО"]]/data()
  let $diff := 
    for $i in 1 to count($second)
    return round ($second[$i] - $self_score[$i], 2)
  let $diff_2 :=
    for $i in 1 to count($diff)
    return if ($diff[$i]<0) then (abs($diff[$i])*2) else ($diff[$i])
  let $diff_summ := sum($diff_2)
  
  let $second_2 := 
    for $i in 1 to count ($second)
    return $second[$i]*(1- round ($diff_2[$i] div $diff_summ, 2))
  let $second_final := 
    for $i in 1 to count ($second_2)
    return round ($second_2[$i] div sum($second_2) * 100, 1)
  return 
    <html>
    <table border="2px">
      <tr align="center" >
        <td>Участник</td>
        <td>оценка 1</td>
        <td>оценка 2</td>
        <td>самооценка</td>
        <td>разница</td>
        <td>добавка (штраф)</td>
        <td>коэффициент</td>
        <td>оценка коррект.</td>
        <td>итоговая в %</td>
      </tr>
      {for $i in 1 to count($data)
      return
        
          <tr align="center">
            <td align="left">{$data[$i]/child::*[@имя/data()="ФИО"]/text()}</td>
            <td >{$first[$i]}</td>
            <td>{$second[$i]}</td>
            <td>{$self_score[$i]}</td>
            <td>{$diff[$i]}</td>
            <td>{$diff_2[$i] }</td> 
            <td>{round(1- round ($diff_2[$i] div $diff_summ, 2), 2)}</td>
            <td>{ round ($second_2[$i], 1)}</td>
            <td>{round ($second_2[$i] div sum($second_2) * 100, 1)}</td>
          </tr>
        }
         <tr align="center">
            <td align="left">{}</td>
            <td>{}</td>
            <td>{}</td>
            <td>{}</td>
            <td>{}</td>
            <td>{}</td> 
            <td>{}</td>
            <td>{}</td>
            <td>{sum($second_final)}</td>
          </tr>  
    </table>
    </html>
};

declare function score:first($data)
{
  let $score :=
    for $i in $data/members/member/text()
    return sum($data/values/row[@имя=$i]/data())
  let $summ := sum($score)
  
  for $i in  $score
  return 
    round (($i div $summ)*100, 1)
};

declare function score:second($data)
{
  let $score :=
    for $i in $data/members/member/text()
    return sum($data/values[row[@имя="ФИО"] != $i]/row[@имя=$i]/data())

  let $summ := sum($score)
  
  for $i in $score
  return round (($i div $summ)*100, 1) 
};