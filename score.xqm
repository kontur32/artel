module namespace score = "http://karlowka.de/score";
declare variable $score:db-name := 'artel';

declare function score:table ($board)
{
  let $data := $board//values
  let $first := score:first($board)
  let $second := score:second($board)
  let $self_score := 
    for $i in $data
    return $i/child::*[@имя/data()=$i/@person/data()]/data()
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
        <td>Общая оценка</td>
        <td>Внешняя оценка</td>
        <td>Самооценка</td>
        <td>Пере-(недо-)оценка</td>
        <td>"Штраф" за пере-(недо-)оценку</td>
        <td>Коэфф. "штрафа"</td>
        <td>Оценка коррект.</td>
        <td>Итоговая оценка в %</td>
      </tr>
      {for $i in 1 to count($data)
      return
        
          <tr align="center">
            <td align="left">{$data[$i]/@person/data()}</td>
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
    return sum($data/values[@person != $i]/row[@имя=$i]/data())

  let $summ := sum($score)
  
  for $i in $score
  return round (($i div $summ)*100, 1) 
};

declare function score:complete ($common as xs:string) as xs:integer
{
   count(db:open($score:db-name)/main/board[@common=$common]/values[row])
};

declare function score:is-complete ($common as xs:string)
{
   let $data := db:open($score:db-name)/main/board[@common=$common]
   let $members-count := count($data//member[text()])
   let $values-count := count($data//values[count(row) > 0])
   return if (  $values-count >= $members-count and  $members-count !=0) then (true()) else (false())
};